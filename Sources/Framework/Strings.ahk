﻿;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;   Modular Simulator Controller System - String Functions                ;;;
;;;                                                                         ;;;
;;;   Author:     Oliver Juwig (TheBigO)                                    ;;;
;;;   License:    (2023) Creative Commons - BY-NC-SA                        ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;-------------------------------------------------------------------------;;;
;;;                    Public Function Declaration Section                  ;;;
;;;-------------------------------------------------------------------------;;;

encode(text) {
	text := StrReplace(text, "\", "\\")
	text := StrReplace(text, "=", "\=")

	return StrReplace(text, "`n", "\n")
}

decode(text) {
	text := StrReplace(StrReplace(StrReplace(text, "\=", "_#_EQ-#_"), "\\", "_#_AC-#_"), "\n", "_#_CR-#_")

	return StrReplace(StrReplace(StrReplace(text, "_#_EQ-#_", "="), "_#_AC-#_", "\"), "_#_CR-#_", "`n")
}

substituteString(text, pattern, replacement) {
	local result := text

	loop {
		text := result

		result := StrReplace(text, pattern, replacement)
	}
	until (result = text)

	return result
}

substituteVariables(text, values := false) {
	local result := text
	local startPos := 1
	local variable, startPos, endPos, value

	loop {
		startPos := InStr(result, "%", , startPos)

		if startPos {
			startPos += 1

			try {
				endPos := InStr(result, "%", false, startPos)

				if endPos {
					variable := Trim(SubStr(result, startPos, endPos - startPos))

					if isInstance(values, Map)
						value := (values && values.Has(variable)) ? values[variable] : %variable%
					else if isInstance(values, Object)
						value := (values && values.HasProp(variable)) ? values.%variable% : %variable%
					else
						value := %variable%

					result := StrReplace(result, "%" . variable . "%", value)
				}
				else
					throw "Second % not found while scanning (" . text . ") for variables in substituteVariables..."
			}
			catch Any as exception {
				logError(exception)
			}
		}
		else
			break
	}

	return result
}

string2Values(delimiter, text, count := false, class := Array) {
	if (class == Array)
		return (count ? StrSplit(Trim(text), delimiter, " `t", count) : StrSplit(Trim(text), delimiter, " `t"))
	else
		return toArray((count ? StrSplit(Trim(text), delimiter, " `t", count) : StrSplit(Trim(text), delimiter, " `t")), class)
}

values2String(delimiter, values*) {
	local result := ""
	local index, value

	for index, value in values {
		if (index > 1)
			result .= delimiter

		result .= value
	}

	return result
}

string2Map(elementSeparator, valueSeparator, text) {
	local result := CaseInsenseMap()
	local ignore, keyValue

	for ignore, keyValue in string2Values(elementSeparator, text) {
		keyValue := string2Values(valueSeparator, keyValue)

		result[keyValue[1]] := keyValue[2]
	}

	return result
}

map2String(elementSeparator, valueSeparator, map) {
	local result := []
	local key, value

	for key, value in map
		result.Push(key . valueSeparator . value)

	return values2String(elementSeparator, result*)
}