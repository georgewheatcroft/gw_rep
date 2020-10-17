package main

import (
	"log"
	"strconv"

	"github.com/360EntSecGroup-Skylar/excelize"
)

func extendSheet(preSlice [][]string, sheetName string) { /*this whole thing is a fix to get around the excelize library not giving you the option to specify no of columns
	in your outputted sheet->slice - this adds vals to specific col to ensure no slice out of bounds issue */

	exe, err := excelize.OpenFile(excelFileName)
	if err != nil {
		log.Fatal(err.Error())
	}
	//get slice, but only use the first and last position to determine first and last data row
	cnt := make([]int, 0)
	i := -1
	for rowNumber, cellStringSlice := range preSlice {
		for rowColumn := range cellStringSlice {
			if rowColumn == 0 && len(cellStringSlice) > 0 {
				if preSlice[rowNumber][rowColumn] != "" { //must be the first or last blank row
					cnt = append(cnt, rowNumber+1) //as we will be working in excel world, need to convert slice numbers before adding
					i++
				}
			}
		}
	}

	extentColumn := columnNameMap(extentColumnInt) //should only extend this far as far as Z if extentColumnInt = 26. as methods use A = 0 due to slice
	var cellFill string
	for rngCount := cnt[0]; rngCount <= cnt[i]; rngCount++ {
		cellFill = extentColumn + strconv.Itoa(rngCount)
		exe.SetCellValue(sheetName, cellFill, "1")
	}
	errSav := exe.Save()
	if errSav != nil {
		log.Fatal(errSav.Error())
	}
}

/*cleans the column we filled to extend the sheet now we have a finished product*/
func cleanSheet(finalSlice [][]string, sheetName string, fileName string) {
	exe, err := excelize.OpenFile(fileName)
	if err != nil {
		log.Fatal(err.Error())
	}

	colToClear := columnNameMap(extentColumnInt)
	for rowNo := range finalSlice {
		if rowNo > 0 { //skip the blank first row which is never extended
			cellToClear := colToClear + strconv.Itoa(rowNo+1) //get around issue with row 1 in excel being index 0 here
			err := exe.SetCellValue(sheetName, cellToClear, "")
			if err != nil {
				log.Fatal(err.Error())
			}
		}
	}
	errSav := exe.Save()
	if errSav != nil {
		log.Fatal(err.Error())
	}

}

//columnNameMap - map int to a column letter
func columnNameMap(toMap int) string {
	named, err := excelize.ColumnNumberToName(toMap)
	if err != nil {
		log.Fatal(err.Error())
	}
	return named
}
func columnLetterToInt(letter string) int {
	number, err := excelize.ColumnNameToNumber(letter)
	if err != nil {
		log.Fatal(err.Error())
	}
	return number
}
