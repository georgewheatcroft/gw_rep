package main

import (
	"fmt"
	"os"
	"strconv"

	"github.com/360EntSecGroup-Skylar/excelize"
)

func duplicateCheckColA(inputSlice [][]string, sheetName string) {

	dupCellSlice := make([]int, 0)
	sliceMaxIndex := len(inputSlice)

	for cnt := 0; cnt < sliceMaxIndex; cnt++ { //go through all the indexes of the slice
		if len(inputSlice[cnt]) > 0 && inputSlice[cnt][0] != "" { //0 = col A

			cellText := inputSlice[cnt][0] //take the text of the index you are looking at for comp.

			for secondCnt := 0; secondCnt < sliceMaxIndex; secondCnt++ { //now loop through the whole slice to see if this occurs again
				if len(inputSlice[secondCnt]) > 0 && cellText != "" && cellText != "1" && cellText == inputSlice[secondCnt][0] { //0 =col A. weirdly some index 0 values can  appear as 1's at this point, so hence no 1's allowed to stop the issue

					//should only ever get to 1 seen, if >=2 then must be duplicates
					dupCellSlice = append(dupCellSlice, secondCnt) //add the row num to slice for reference
				}

			}
			if len(dupCellSlice) > 1 {
				fmt.Println("duplicates have been found! these shall be highlighted in red")
				highlightColADuplicates(dupCellSlice, sheetName)
			}
			dupCellSlice = make([]int, 0) //remake the slice and clear the old results away
		}

	}
}

func highlightColADuplicates(dupCellSlice []int, sheetName string) {
	var rowNumStr string
	var cellRefStr string
	highlightExe, err := excelize.OpenFile(outputFileName)
	if err != nil {
		fmt.Println(err)
		fmt.Println(dupCheckFailed)
		os.Exit(4)
	}
	if len(dupCellSlice) > 1 && sheetName != "" { //just to try and stop a panic from occuring if dodgy data passed
		//should give red colour fill if  #FF0000 or blue if #E0EBF5. see http://dmcritchie.mvps.org/excel/colors.htm (no l at end)
		style, err := highlightExe.NewStyle(`{"fill":{"type":"gradient","color":["#FF0000","#FF0000"],"shading":1}}`)
		if err != nil {
			fmt.Println(err.Error())
			fmt.Println(dupCheckFailed)
			os.Exit(5)
		}

		for _, rowNum := range dupCellSlice {
			rowNum = rowNum + 1 //as it will need to be in the excel format (count from 1, rather than 0)
			rowNumStr = strconv.Itoa(rowNum)
			cellRefStr = "A" + rowNumStr
			err := highlightExe.SetCellStyle(sheetName, cellRefStr, cellRefStr, style)
			if err != nil {
				fmt.Println(err.Error())
				fmt.Println(dupCheckFailed)
				os.Exit(6)
			}
			fmt.Println("did highlighting")
			errSav := highlightExe.Save()
			if errSav != nil { //save output excel file as this stops panic from trying to open file in next iteration and ensures changes kept
				fmt.Println(errSav)
				fmt.Println(dupCheckFailed)
				os.Exit(999) //die very badly if can't be done!
			}
			fmt.Println("did saving")
		}

	}
}
