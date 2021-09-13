;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;   Modular Simulator Controller System - Database                        ;;;
;;;                                                                         ;;;
;;;   Author:     Oliver Juwig (TheBigO)                                    ;;;
;;;   License:    (2021) Creative Commons - BY-NC-SA                        ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;-------------------------------------------------------------------------;;;
;;;                         Global Include Section                          ;;;
;;;-------------------------------------------------------------------------;;;

#Include ..\Includes\Includes.ahk


;;;-------------------------------------------------------------------------;;;
;;;                          Public Classes Section                         ;;;
;;;-------------------------------------------------------------------------;;;

class Database {
	iDirectory := false
	iSchemas := false
	iTables := {}
	
	Directory[] {
		Get {
			return this.iDirectory
		}
	}
	
	Schemas[name := false] {
		Get {
			return (name ? this.iSchemas[name] : this.iSchemas)
		}
	}
	
	Tables[name := false] {
		Get {
			if name {
				if !this.iTables.HasKey(name) {
					schema := this.Schemas[name]
					data := []
					
					Loop Read, % (this.Directory . name . ".CSV")
					{
						row := {}
						values := string2Values(";", A_LoopReadLine)
						
						for ignore, column in schema
							row[column] := values[A_Index]
						
						data.Push(row)
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
		this.iDirectory := directory
		this.iSchemas := schemas
	}
	
	query(name, query) {
		schema := this.Schemas[name]
		rows := this.Tables[name]
		projection := (query.HasKey("Select") ? query["Select"] : false)
		
		if query.HasKey("Filter") {
			filter := query["Filter"]
			selection := []
			
			for ignore, row in rows
				if %filter%(row)
					selection.Push(row)
			
			rows := selection
		}
		else if !projection
			rows := rows.Clone()
	
		if projection {
			projectedRows := []
			
			for ignore, row in rows {
				projectedRow := {}
			
				for ignore, column in projection
					projectedRow[column] := row[column]
				
				projectedRows.Push(projectedRow)
			}
			
			rows := projectedRows
		}
		
		if query.HasKey("GroupBy") {
			groupBy := query["GroupBy"]
			groupedRows := {}
			
			while (rows.Length() > 0) {
				row := rows.Pop()
			
				key := []
				
				for ignore, column in groupBy
					key.Push(row[column])
				
				key := values2String("|", key*)
				
				if !groupedRows.HasKey(key)
					groupedRows[key] := []
				
				groupedRows[key].Push(row)
			}
			
			rows := []
			
			for ignore, rowGroup in groupedRows
				rows.Push(rowGroup)
		
			if query.HasKey("Combine") {
				combine := query["Combine"]
				
				for index, row in rows
					rows[index] := %combine%(rows[index])
			}
		}
		
		return rows
	}
	
	flush(name := false) {
		if name {
			if this.Table.HasKey(name) {
				directory := this.Directory
				fileName := (directory . name . ".CSV")
				
				FileCreateDir %directory%
				
				try {
					FileDelete %fileName%
				}
				catch exception {
					; ignore
				}
				
				for ignore, row in this.Tables[name] {
					row := (values2String(";", row*) . "`n")
		
					FileAppend %row%, %fileName%
				}
			}
		}
		else
			for name, ignore in this.Tables
				this.flush(name)
	}
	
	reload(flush := true) {
		if flush
			this.flush()
		
		this.iTables := {}
	}
	
	add(name, values, flush := false) {
		row := []
			
		for ignore, column in this.Schemas[name]
			row.Push(values.HasKey(column) ? values[column] : kUndefined)
		
		if this.Tables.HasKey(name)
			this.Tables[name].Push(row)
		
		if flush {
			directory := this.Directory
			fileName := (directory . name . ".CSV")
			
			FileCreateDir %directory%
					
			row := (values2String(";", row*) . "`n")
			
			FileAppend %row%, %fileName%
		}
	}
	
	remove(name, filter, flush := false) {
		rows := []
		
		for ignore, row in this.Tables[name]
			if !%filter%(row)
				rows.Push(row)
		
		this.iTables[name] := rows
		
		if flush
			this.flush(name)
	}
}