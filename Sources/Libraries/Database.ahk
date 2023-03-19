﻿;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;   Modular Simulator Controller System - Database                        ;;;
;;;                                                                         ;;;
;;;   Author:     Oliver Juwig (TheBigO)                                    ;;;
;;;   License:    (2023) Creative Commons - BY-NC-SA                        ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;-------------------------------------------------------------------------;;;
;;;                         Global Include Section                          ;;;
;;;-------------------------------------------------------------------------;;;

#Include "..\Framework\Framework.ahk"


;;;-------------------------------------------------------------------------;;;
;;;                          Local Include Section                          ;;;
;;;-------------------------------------------------------------------------;;;

#Include "..\Libraries\Math.ahk"


;;;-------------------------------------------------------------------------;;;
;;;                          Public Classes Section                         ;;;
;;;-------------------------------------------------------------------------;;;

class Database {
	iDirectory := false
	iSchemas := false
	iTables := {}
	iFiles := {}
	iTableChanged := {}

	Directory {
		Get {
			return this.iDirectory
		}
	}

	Schemas[name := false] {
		Get {
			return (name ? this.iSchemas[name] : this.iSchemas)
		}
	}

	Files[name := false] {
		Get {
			return (name ? this.iFiles[name] : this.iFiles)
		}
	}

	Tables[name := false] {
		Get {
			local schema, data, row, values, length, ignore, column
			local file, line

			if name {
				if !this.iTables.Has(name) {
					schema := this.Schemas[name]
					data := []

					if this.Directory {
						file := this.Files[name]

						if file {
							file.Position := 0

							while !file.AtEOF {
								line := Trim(file.ReadLine(), " `t`n`r")

								row := Map()
								values := string2Values(";", line)
								length := values.Length

								for ignore, column in schema
									if (length >= A_Index)
										row[column] := values[A_Index]
									else
										row[column] := kNull

								data.Push(row)
							}
						}
						else
							loop Read, (this.Directory . name . ".CSV")
							{
								row := Map()
								values := string2Values(";", A_LoopReadLine)
								length := values.Length

								for ignore, column in schema
									if (length >= A_Index)
										row[column] := values[A_Index]
									else
										row[column] := kNull

								data.Push(row)
							}
					}

					this.iTables[name] := data
				}

				return this.iTables[name]
			}
			else
				return this.iTables
		}
	}

	__New(directory, schemas) {
		this.iDirectory := (normalizeDirectoryPath(directory) . "\")
		this.iSchemas := schemas
	}

	lock(name := false, wait := true) {
		local done := false
		local locked := []
		local directory, file, ignore, result

		if (!name && !wait)
			throw "Inconsistent parameters detected in Database.lock..."

		if name {
			if !this.Files.Has(name) {
				while !done {
					directory := this.Directory

					DirCreate(directory)

					try {
						file := FileOpen(directory . name . ".CSV", "rw-rwd")
					}
					catch Any as exception {
						logError(exception)

						file := false
					}

					if (!file && wait)
						Sleep(100)
					else
						done := true
				}

				if file {
					this.Files[name] := file

					return true
				}
				else
					return false
			}
			else
				return true
		}
		else {
			result := true

			for name, ignore in getKeys(this.Schemas)
				if this.lock(name, wait)
					locked.Push(name)
				else {
					result := false

					break
				}

			if !result
				for ignore, name in locked
					this.unlock(name)

			return result
		}
	}

	unlock(name := false) {
		local file, ignore

		if name {
			file := this.Files[name]

			if file {
				this.flush(name)

				this.Files.Delete(name)

				file.Close()
			}
			else
				throw "Trying to unlock a file that is not locked in Database.unlock..."
		}
		else
			for name, ignore in getKeys(this.Schemas)
				this.unlock(name)

	}

	query(name, query) {
		local predicate, schema, transform, rows, needsClone, predicate, selection, ignore, row, projection, projectedRows
		local column, projectedRow

		schema := this.Schemas[name]
		rows := this.Tables[name]
		needsClone := true

		if query.Has("Where") {
			predicate := query["Where"]
			selection := []

			if !predicate.MinParams
				predicate := constraintColumns.Bind(predicate)

			for ignore, row in rows
				if %predicate%(row)
					selection.Push(row)

			rows := selection
			needsClone := false
		}

		if query.Has("Transform") {
			transform := query["Transform"]

			rows := %transform%(rows)
		}

		if (query.Has("Group") || query.Has("By")) {
			rows := groupRows(query.Has("By") ? query["By"] : [], query.Has("Group") ? query["Group"] : [], rows)
			needsClone := false
		}

		if query.Has("Select") {
			projection := query["Select"]
			projectedRows := []

			for ignore, row in rows {
				projectedRow := {}

				for ignore, column in projection
					projectedRow[column] := row[column]

				projectedRows.Push(projectedRow)
			}

			rows := projectedRows
			needsClone := false
		}

		return (needsClone ? rows.Clone() : rows)
	}

	reload(name, flush := true) {
		if flush
			this.flush(name)

		this.iTables.Delete(name)
	}

	add(name, values, flush := false) {
		local tries := 10
		local row, directory, fileName, ignore, column, file

		this.Tables[name].Push(values)

		if flush {
			row := []

			for ignore, column in this.Schemas[name]
				row.Push(values.Has(column) ? values[column] : kNull)

			file := this.Files[name]

			if file {
				file.Position := file.Length

				file.WriteLine(values2String(";", row*))
			}
			else {
				directory := this.Directory
				fileName := (directory . name . ".CSV")

				DirCreate(directory)

				row := (values2String(";", row*) . "`n")

				loop
					try {
						FileAppend(row, fileName)

						break
					}
					catch Any as exception {
						if (tries-- > 0)
							Sleep(10)
						else
							throw Exception
					}
			}
		}
		else
			this.iTableChanged[name] := true
	}

	combine(table, query, field, values) {
		local results := []
		local ignore, value, result

		for ignore, value in values {
			query.Where[field] := value

			for ignore, result in this.query(table, query)
				results.Push(result)
		}

		return results
	}

	remove(name, where, predicate := false, flush := false) {
		local rows := []
		local ignore, row

		if (where && !where.MinParams)
			where := constraintColumns.Bind(where)

		for ignore, row in this.Tables[name]
			if (!where || %where%(row)) {
				if (!predicate || !%predicate%(row))
					rows.Push(row)
			}
			else
				rows.Push(row)

		this.iTables[name] := rows
		this.iTableChanged[name] := true

		if flush
			this.flush(name)
	}

	clear(name, flush := false) {
		this.iTables[name] := []
		this.iTableChanged[name] := true

		if flush
			this.flush(name)
	}

	changed(name) {
		this.iTableChanged[name] := true
	}

	flush(name := false) {
		local bakFile := false
		local directory, fileName, schema, ignore, row, values, column, file

		if name {
			if (this.Tables.Has(name) && this.iTableChanged.Has(name)) {
				directory := this.Directory
				fileName := (directory . name . ".CSV")
				file := this.Files[name]

				if file {
					try {
						file.Position := 0

						bakFile := FileOpen(fileName . ".bak", "w")

						bakFile.Write(file.Read())
					}
					catch Any as exception {
					}
					finally {
						if bakFile
							bakFile.Close()
					}

					file.Length := 0

					schema := this.Schemas[name]

					for ignore, row in this.Tables[name] {
						values := []

						for ignore, column in schema
							values.Push(row.Has(column) ? row[column] : kNull)

						file.WriteLine(values2String(";", values*))
					}
				}
				else {
					directory := this.Directory
					fileName := (directory . name . ".CSV")

					DirCreate(directory)

					deleteFile(fileName, true)

					schema := this.Schemas[name]

					for ignore, row in this.Tables[name] {
						values := []

						for ignore, column in schema
							values.Push(row.Has(column) ? row[column] : kNull)

						row := (values2String(";", values*) . "`n")

						FileAppend(row, fileName)
					}
				}

				this.iTableChanged.Delete(name)
			}
		}
		else
			for name, ignore in this.Tables
				this.flush(name)
	}
}


;;;-------------------------------------------------------------------------;;;
;;;                    Public Function Declaration Section                  ;;;
;;;-------------------------------------------------------------------------;;;

valueOrNull(value) {
	return ((value != "") ? value : kNull)
}

always(value, ignore*) {
	return value
}


;;;-------------------------------------------------------------------------;;;
;;;                    Private Function Declaration Section                 ;;;
;;;-------------------------------------------------------------------------;;;

constraintColumns(constraints, row) {
	local column, value

	for column, value in constraints
		if (row.Has(column) && (row[column] != value))
			return false

	return true
}

groupRows(groupedByColumns, groupedColumns, rows) {
	local values := Map()
	local function, ignore, row, column, key, result, group, groupedRows, columnValues
	local resultRow, valueColumn, resultColumn, columnDescriptor

	if !IsObject(groupedByColumns)
		groupedByColumns := Array(groupedByColumns)

	for ignore, row in rows {
		key := []

		for ignore, column in groupedByColumns
			key.Push(row[column])

		key := values2String("|", key*)

		if values.Has(key)
			values[key].Push(row)
		else
			values[key] := Array(row)
	}

	result := []

	for group, groupedRows in values {
		group := string2Values("|", group)

		resultRow := {}

		for ignore, column in groupedByColumns
			resultRow[column] := group[A_Index]

		for ignore, columnDescriptor in groupedColumns {
			valueColumn := columnDescriptor[1]
			function := columnDescriptor[2]
			resultColumn := columnDescriptor[3]

			columnValues := []

			for ignore, row in groupedRows
				columnValues.Push(row[valueColumn])

			resultRow[resultColumn] := %function%(columnValues)
		}

		result.Push(resultRow)
	}

	return result
}