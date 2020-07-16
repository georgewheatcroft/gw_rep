package main

import (
	"fmt"
	"os"
	"strconv"

	"github.com/360EntSecGroup-Skylar/excelize"
)

func extendSheet(preSlice [][]string, sheetName string) { /*this whole thing is a fix to get around the excelize library not giving you the option to specify no of columns
	in your outputted sheet->slice - this adds vals to specific col to ensure no slice out of bounds issue */

	exe, err := excelize.OpenFile(excelFileName)
	if err != nil {
		fmt.Println(err)
		fmt.Println("could not extend the sheet range in predata extraction")
		os.Exit(7)
	}
	//get slice, but only use the first and last position to determine first and last data row
	cnt := make([]int, 0)
	i := -1
	for rowNumber, cellStringSlice := range preSlice {
		for rowColumn := range cellStringSlice {
			if rowColumn == 0 && len(cellStringSlice) > 0 {
				if preSlice[rowNumber][rowColumn] != "" {
					cnt = append(cnt, rowNumber+1) //as we will be working in excel world, need to convert slice numbers before adding
					i++
				}
			}
		}
	}
	if i <= 2 {
		fmt.Println("couldn't get data range in sheets")
		os.Exit(7)
	}
	extentColumn := columnNameMap(extentColumnInt) //should only extend this far as far as Z if extentColumnInt = 25. as methods use A = 0 due to slice
	var cellFill string
	for rngCount := cnt[0]; rngCount <= cnt[i]; rngCount++ {
		cellFill = extentColumn + strconv.Itoa(rngCount)
		exe.SetCellValue(sheetName, cellFill, "1")
	}
	errSav := exe.Save() //hopefully..
	if errSav != nil {
		fmt.Println(errSav)
		os.Exit(7)
	}
}

func columnNameMap(toMap int) string {
	named, err := excelize.ColumnNumberToName(toMap)
	if err != nil {
		fmt.Println("found an issue with mapping column names in columnNameMap")
		fmt.Println(err)
		os.Exit(10)
	}
	return named
}
func columnLetterToInt(letter string) int {
	number, err := excelize.ColumnNameToNumber(letter)
	if err != nil {
		fmt.Println("found an issue with mapping column number in columnLetterToInt")
		fmt.Println(err)
		os.Exit(11)
	}
	return number
}
