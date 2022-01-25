;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;   Modular Simulator Controller System - Mathematical Functions          ;;;
;;;                                                                         ;;;
;;;   Author:     Oliver Juwig (TheBigO)                                    ;;;
;;;   License:    (2022) Creative Commons - BY-NC-SA                        ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
;;;-------------------------------------------------------------------------;;;
;;;                     Public Function Declaration Section                 ;;;
;;;-------------------------------------------------------------------------;;;

minimum(numbers) {
	min := 0
	
	for ignore, number in numbers
		min := (!min ? number : Min(min, number))

	return min
}

maximum(numbers) {
	max := 0
	
	for ignore, number in numbers
		max := (!max ? number : Max(max, number))

	return max
}

average(numbers) {
	avg := 0
	
	for ignore, value in numbers
		avg += value
	
	return (avg / count(numbers))
}

stdDeviation(numbers) {
	avg := average(numbers)
	
	squareSum := 0
	
	for ignore, value in numbers
		squareSum += ((value - avg) * (value - avg))

	squareSum := (squareSum / count(numbers))
	
	return Sqrt(squareSum)
}

count(values) {
	return values.Length()
}

linRegression(xValues, yValues, ByRef a, ByRef b) {
	xAverage := average(xValues)
	yAverage := average(yValues)
	
	dividend := 0
	divisor := 0
	
	for index, xValue in xValues {
		xDelta := (xValue - xAverage)
		yDelta := (yValues[index] - yAverage)
		
		dividend += (xDelta * yDelta)
		divisor += (xDelta * xDelta)
	}
	
	b := (dividend / divisor)
	a := (yAverage - (b * xAverage))
}