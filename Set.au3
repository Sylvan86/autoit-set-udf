#include-once
#include <Array.au3>

; #INDEX# =======================================================================================================================
; Title .........: Set
; AutoIt Version : 3.3.14.2
; Language ......: English
; Description ...: implement a set datatype and various mathematical functionality for them
; Author(s) .....: AspirinJunkie
; License .......: This work is free.
;                  You can redistribute it and/or modify it under the terms of the Do What The Fuck You Want To Public License, Version 2,
;                  as published by Sam Hocevar.
;                  See http://www.wtfpl.net/ for more details.
; ===============================================================================================================================

; #CURRENT# =====================================================================================================================
;
; · basic set functionality
;     - create set out of array(1D/2D), object or scalar values
;     - add and delete elements to/from the set
;     - convert set to array
;     - display set like _ArrayDisplay()
;
; · mathematical set functions:
;     - union of two sets
;     - intersection of two sets
;     - difference of two sets
;     - symmetric difference of two sets
;     - calculate complex algebraic statements
;
; · helper functions:
;     - check if variable is a set
;     - cloning a dictionary object
;
; ===============================================================================================================================


#Region Main-function
If @ScriptName = "Set.au3" Then

	; example values
	Local $a_Test_1[] = [1, 2, 3, 4, 5]
	Local $a_Test_2[] = [4, 5, 6, 7, 8, 9]
	Local $a_Test_3[] = [4,5,6,7,8]

	; create sets out of example arrays
	$o_Set_1 = _set_Create($a_Test_1)
	$o_Set_2 = _set_Create($a_Test_2)
	$o_Set_3 = _set_Create($a_Test_3)

	; add one or more values:
	_set_Add($o_Set_1, 6)
	Local $a_Temp[] = [10, 11, 12]
	_set_Add($o_Set_1, $a_Temp)

	; delete one or more values:
	_set_Delete($o_Set_1, 6)
	_set_Delete($o_Set_1, $a_Temp)

	; calculate union A∪B of two sets:
	Local $o_Union = _set_Union($o_Set_1, $o_Set_2)
	_set_Display($o_Union, "union A∪B")

	; calculate intersection A∩B of two sets:
	Local $o_Intersection = _set_Intersect($o_Set_1, $o_Set_2)
	_set_Display($o_Intersection, "intersect A∩B")

	; calculate the difference A-B (also A\B ):
	Local $o_difference = _set_Difference($o_Set_1, $o_Set_2)
	_set_Display($o_difference, "difference A-B")

	; calculate the symmetric difference A△B :
	Local $o_SymDifference = _set_SymDifference($o_Set_1, $o_Set_2)
	_set_Display($o_SymDifference, "symmetric difference A△B")

	; calculate complex algebraic statements
	$o_Result = _set_algebraic("AuB-(Bn(AuA)uC)", $o_Set_1, $o_Set_2, $o_Set_3)
	_set_Display($o_Result, "AuB-(Bn(AuA)uC)")

	; check if a value exist in the set:
	If _set_Contain($o_Set_1, 4) Then MsgBox(0,"", "value '4' exists in $o_Set_1")

	; check if another if a set A is subset of B:
	Local $a_Vals[] = [2,3,4]
	Local $o_A = _set_Create($a_Vals)
	If _set_Contain($o_Set_1, $o_A) Then MsgBox(0,"", "$o_A is a subset of $o_Set_1" & @CRLF & "( o_A ⊆ o_Set_1 )")

	; convert set to array:
	Local $a_Array = _set_ToArray($o_SymDifference)
	_ArrayDisplay($a_Array, "converted array")
EndIf
#EndRegion Main-function





#Region mathematical set operations
; #FUNCTION# ======================================================================================
; Name ..........: _set_algebraic()
; Description ...: calculate complex algebra of sets statements
; Syntax ........: _set_algebraic($s_statement, $A[, $B = Default[, $C = Default[, $D = Default[, $E = Default[, $F = Default[, $G = Default[, $H = Default]]]]]]])
; Parameters ....: $s_statement - the statement as string (see remarks)
;                  $A           - the set which should be inserted for "A" in the statement
;                  $B - $G      - [optional] additional sets which should be inserted in the statement
;                  $H           - [optional] internal use only! (default:Default)
; Return values .: Success: the resulting set
;                  Failure: Set @error
; Author ........: AspirinJunkie
; Remarks .......: statement syntax:
;					A,B,C,D,E,F,G : sets from the function parameters
;                   operators: n (intersection), u (union), - (difference), s (symmetric difference
;                   (...) : brackets for influence the order of operations
; Related .......: _set_Difference, _set_Intersect, _set_SymDifference, _set_Union
; Example .......: Yes
;                  ; example values
;                  Local $a_Test_1[] = [1, 2, 3, 4, 5], $a_Test_2[] = [4, 5, 6, 7, 8, 9], $a_Test_3[] = [4,5,6,7,8]
;                  ; create sets out of example arrays
;                  Local $o_Set_1 = _set_Create($a_Test_1), $o_Set_2 = _set_Create($a_Test_2), $o_Set_3 = _set_Create($a_Test_3)
;                  ; calculate complex algebraic statements
;                  $o_Result = _set_algebraic("AuB-(Bn(AuA)uC)", $o_Set_1, $o_Set_2, $o_Set_3)
;                  _set_Display($o_Result)
; =================================================================================================
Func _set_algebraic($s_statement, $A, $B = Default, $C = Default, $D = Default, $E = Default, $F = Default, $G = Default, $H = Default)
	Local $o_Left, $o_Right, $a_RE, $i_Left, $i_OpEnd, $s_Operator
	If StringLeft($s_statement, 1) = "(" And StringRight($s_statement, 1) = ")" Then $s_statement = StringTrimLeft(StringTrimRight($s_statement, 1), 1)

	; the left operand:
	$a_RE = StringRegExp($s_statement, "\G\s*([A-H])", 1)
	If Not @error Then
		$i_Left = @extended
		$o_Left = Eval($a_RE[0])
	Else
		$a_RE = StringRegExp($s_statement, "(?x)(?(DEFINE)(?<open>\()(?<close>\))(?<nonparens>[^\(\)])(?<nested_parens>(?&open)(?:(?&nonparens)*+|(?&nested_parens))*(?&close)))\G\s*(?&nested_parens)", 1)
		$i_Left = @extended
		If @error Then Return SetError(1) ; wrong syntax
		$o_Left = _set_algebraic(StringTrimLeft(StringTrimRight($a_RE[0], 1), 1), $A, $B, $C, $D, $E, $F, $G, $H)
	EndIf

	; the operator:
	$a_RE = StringRegExp($s_statement, "\G\s*([nu\-s])\s*", 1, $i_Left)
	If @error Then Return SetError(2, $i_Left)
	$i_OpEnd = @extended
	$s_Operator = $a_RE[0]

	; the right operand:
	$a_RE = StringRegExp($s_statement, "\G\s*([A-H])", 1, $i_OpEnd)
	If Not @error Then
		$i_Right = @extended
		$o_Right = Eval($a_RE[0])
	Else
		$a_RE = StringRegExp($s_statement, "(?x)(?(DEFINE)(?<open>\()(?<close>\))(?<nonparens>[^\(\)])(?<nested_parens>(?&open)(?:(?&nonparens)*+|(?&nested_parens))*(?&close)))\G\s*(?&nested_parens)", 1, $i_OpEnd)
		$i_Right = @extended
		If @error Then Return SetError(3, $i_OpEnd) ; wrong syntax
		$o_Right = _set_algebraic(StringTrimLeft(StringTrimRight($a_RE[0], 1), 1), $A, $B, $C, $D, $E, $F, $G, $H)
	EndIf

	Local $o_Ret
	Switch $s_Operator
		Case "n" ; intersection
			$o_Ret = _set_Intersect($o_Left, $o_Right)
		Case "u"
			$o_Ret = _set_Union($o_Left, $o_Right)
		Case "-"
			$o_Ret = _set_Difference($o_Left, $o_Right)
		Case "s"
			$o_Ret = _set_SymDifference($o_Left, $o_Right)
	EndSwitch

	Local $a_Rest = StringRegExp($s_statement, "\G\s*([nu\-s].*)", 1, $i_Right)
	If Not @error Then
		$o_Ret = _set_algebraic("H" & $a_Rest[0], $A, $B, $C, $D, $E, $F, $G, $o_Ret)
	EndIf

	Return $o_Ret
EndFunc   ;==>_set_algebraic

; #FUNCTION# ======================================================================================
; Name ..........: _set_Union()
; Description ...: calculate union A∪B of two sets
; Syntax ........: _set_Union(ByRef $o_Set1, ByRef $o_Set2)
; Parameters ....: ByRef $o_Set1 - set A
;                  ByRef $o_Set2 - set B
; Return values .: Success: a new set with the union of the two sets
;                  Failure: Set @error = 1 : at least one parameter is not a set type
; Author ........: AspirinJunkie
; =================================================================================================
Func _set_Union(ByRef $o_Set1, ByRef $o_Set2)
	If Not (__set_IsSet($o_Set1) And __set_IsSet($o_Set2)) Then Return SetError(1)
	Local $o_Ret = __set_CloneDic($o_Set1)
	_set_Add($o_Ret, $o_Set2)
	Return $o_Ret
EndFunc   ;==>_set_Union

; #FUNCTION# ======================================================================================
; Name ..........: _set_Intersect()
; Description ...: calculate intersection A∩B of two sets
; Syntax ........: _set_Intersect(ByRef $o_Set1, ByRef $o_Set2)
; Parameters ....: ByRef $o_Set1 - set A
;                  ByRef $o_Set2 - set B
; Return values .: Success: a new set with the intersection A∩B
;                  Failure: Set @error = 1 : at least one parameter is not a set type
; Author ........: AspirinJunkie
; =================================================================================================
Func _set_Intersect(ByRef $o_Set1, ByRef $o_Set2)
	If Not (__set_IsSet($o_Set1) And __set_IsSet($o_Set2)) Then Return SetError(1)
	Local $o_Ret = ObjCreate("Scripting.Dictionary")
	For $o_Key In $o_Set1
		If $o_Set2.Exists($o_Key) Then $o_Ret($o_Key) = 0
	Next
	Return $o_Ret
EndFunc   ;==>_set_Intersect

; #FUNCTION# ======================================================================================
; Name ..........: _set_Difference()
; Description ...: calculate the difference A-B (also A\B )
; Syntax ........: _set_Difference(ByRef $o_Set1, ByRef $o_Set2)
; Parameters ....: ByRef $o_Set1 - set A
;                  ByRef $o_Set2 - set B
; Return values .: Success: a new set with the difference A-B
;                  Failure: Set @error = 1 : at least one parameter is not a set type
; Author ........: AspirinJunkie
; =================================================================================================
Func _set_Difference(ByRef $o_Set1, ByRef $o_Set2)
	If Not (__set_IsSet($o_Set1) And __set_IsSet($o_Set2)) Then Return SetError(1)
	Local $o_Ret = ObjCreate("Scripting.Dictionary")
	For $o_Key In $o_Set1
		If Not $o_Set2.Exists($o_Key) Then $o_Ret($o_Key) = 0
	Next
	Return $o_Ret
EndFunc   ;==>_set_Difference

; #FUNCTION# ======================================================================================
; Name ..........: _set_SymDifference()
; Description ...: calculate the symmetric difference A△B
; Syntax ........: _set_SymDifference(ByRef $o_Set1, ByRef $o_Set2)
; Parameters ....: ByRef $o_Set1 - set A
;                  ByRef $o_Set2 - set B
; Return values .: Success: a new set with the symmetric difference A△B
;                  Failure: Set @error = 1 : at least one parameter is not a set type
; Author ........: AspirinJunkie
; =================================================================================================
Func _set_SymDifference(ByRef $o_Set1, ByRef $o_Set2)
	If Not (__set_IsSet($o_Set1) And __set_IsSet($o_Set2)) Then Return SetError(1)
	Local $o_Ret = ObjCreate("Scripting.Dictionary")
	For $o_Key In $o_Set1
		If Not $o_Set2.Exists($o_Key) Then $o_Ret($o_Key) = 0
	Next
	For $o_Key In $o_Set2
		If Not $o_Set1.Exists($o_Key) Then $o_Ret($o_Key) = 0
	Next
	Return $o_Ret
EndFunc   ;==>_set_SymDifference
#EndRegion mathematical set operations

#Region elementary set functions
; #FUNCTION# ======================================================================================
; Name ..........: _set_Contain()
; Description ...: checks if a value exists in or a list of values is a subset of a set: $o_Values ⊆ $o_Set ?
; Syntax ........: _set_Contain($o_Set, $o_Values)
; Parameters ....: $o_Set    - the set where to check
;                  $o_Values - the value[s] to check (scalar, set or 1D array)
; Return values .: Success: True if $o_set completely contain $o_Values, False if not
;                  Failure: set @error
; Author ........: AspirinJunkie
; =================================================================================================
Func _set_Contain($o_Set, $o_Values)
	If Not __set_IsSet($o_Set) Then Return SetError(1)

	Select
		Case IsArray($o_Values)
			If UBound($o_Values,0) <> 1 Then Return SetError(2, UBound($o_Values,0))
			For $i In $o_Values
				If Not $o_Set.Exists($i) Then Return False
			Next
		Case __set_IsSet($o_Values)
			For $o_Key In $o_Values
				If Not $o_Set.Exists($o_Key) Then Return False
			Next
		Case Else
			Return $o_Set.Exists($o_Values)
	EndSelect
	Return True
EndFunc   ;==>_set_Create

; #FUNCTION# ======================================================================================
; Name ..........: _set_Create()
; Description ...: create a new set-variable out of array, set, dictionary or scalar
; Syntax ........: _set_Create([$a_Array = Default[, $i_2D = 0[, $i_Start = 0[, $i_End = Default]]]])
; Parameters ....: $a_Array - [optional] values from array (1D or 2D) or scalar(number, string, object, binary) (default:Default)
;                             if Default: new empty set is returned
;                  $i_2D    - [optional] column of values when $a_Array = 2D-array (default:0)
;                  $i_Start - [optional] start index when $a_Array = Array (default:0)
;                  $i_End   - [optional] end index when $a_Array = Array (default:Default)
; Return values .: Success: a set variable (=Scripting.Dictionary object)
;                  Failure: Set @error:
;                               1 = wrong variable type for $a_Array
;                               2 = array has more than 1 or 2 dimensions
;                               3 = wrong value for $i_Start
;                               4 = wrong value for $i_End
;                               5 = wrong value for $i_2D
; Author ........: AspirinJunkie
; Example .......: Yes
;                  Local $a_Test_1[] = [1, 2, 3, 4, 5]
;                  $o_Set_1 = _set_Create($a_Test_1)
;                  $o_Set_2 = _set_Create(15)
; =================================================================================================
Func _set_Create($a_Array = Default, $i_2D = 0, $i_Start = 0, $i_End = Default)
	If $a_Array = Default Then Return ObjCreate("Scripting.Dictionary")

	Local $o_Set = ObjCreate("Scripting.Dictionary")

	If IsArray($a_Array) Then
		If UBound($a_Array, 0) > 2 Then Return SetError(2, UBound($a_Array, 0)) ; too much dims for Array

		If $i_Start >= UBound($a_Array) Or $i_Start < 0 Then Return SetError(3, $i_Start) ; wrong $i_Start
		If $i_End = Default Then $i_End = UBound($a_Array) - 1
		If $i_End >= UBound($a_Array) Or $i_End < 0 Or $i_End < $i_Start Then Return SetError(4, $i_End) ; Wrong $i_End

		If UBound($a_Array, 0) = 2 Then ; 2D Array
			If $i_2D < 0 Or $i_2D >= UBound($a_Array, 2) Then Return SetError(5, $i_2D) ; wrong $i_2D
			For $i = $i_Start To $i_End
				$o_Set($a_Array[$i][$i_2D]) = 0
			Next
		Else ; 1D Array
			For $i = $i_Start To $i_End
				$o_Set($a_Array[$i]) = 0
			Next
		EndIf
	ElseIf IsNumber($a_Array) Or IsString($a_Array) Or IsObj($a_Array) Or IsBinary($a_Array) Then ; Scalar value
		$o_Set($a_Array) = 1
	Else
		Return SetError(1)
	EndIf

	Return $o_Set
EndFunc   ;==>_set_Create

; #FUNCTION# ======================================================================================
; Name ..........: _set_Delete()
; Description ...: delete elements from a set
; Syntax ........: _set_Delete(ByRef $o_Set, $o_Values, Const[ $i_2D = 0])
; Parameters ....: ByRef $o_Set - the set where the element[s] should be deleted
;                  $o_Values    - the values which should be deleted (var type like $a_Array in _set_Create() )
; Return values .: Success: True
;                  Failure: False and set @error to:
;                       1 = $o_Set is not a correct set variable
;                       2 = wrong form for $o_Values
; Author ........: AspirinJunkie
; Related .......: __set_IsSet, _set_Create
; Example .......: Yes
;                  _set_Delete($o_Set_1, 6)
;                  _set_Delete($o_Set_1, $a_Temp)
; =================================================================================================
Func _set_Delete(ByRef $o_Set, $o_Values)
	If Not __set_IsSet($o_Set) Then Return SetError(1, 0, False)
	If Not __set_IsSet($o_Values) Then $o_Values = _set_Create($o_Values)
	If @error Then Return SetError(2, @error, False)

	For $o_Key In $o_Values
		If $o_Set.Exists($o_Key) Then $o_Set.Remove($o_Key)
	Next

	Return True
EndFunc   ;==>_set_Delete

; #FUNCTION# ======================================================================================
; Name ..........: _set_Add()
; Description ...: add elements to a set
; Syntax ........: _set_Add(ByRef $o_Set, $o_Values, Const[ $i_2D = 0])
; Parameters ....: ByRef $o_Set - the set where the element[s] should be added
;                  $o_Values    - the values which should be added (var type like $a_Array in _set_Create() )
;                  Const $i_2D  - [optional]  (default:0)
; Return values .: Success: True
;                  Failure: False and set @error to:
;                       1 = $o_Set is not a correct set variable
;                       2 = wrong form for $o_Values
; Author ........: AspirinJunkie
; Example .......: Yes
;                  _set_Add($o_Set_1, 6)
;                  Local $a_Temp[] = [10, 11, 12]
;                  _set_Add($o_Set_1, $a_Temp)
; =================================================================================================
Func _set_Add(ByRef $o_Set, $o_Values)
	If Not __set_IsSet($o_Set) Then Return SetError(1, 0, False)
	If Not __set_IsSet($o_Values) Then $o_Values = _set_Create($o_Values)
	If @error Then Return SetError(2, @error, False)

	For $o_Key In $o_Values
		$o_Set($o_Key) = 1
	Next

	Return True
EndFunc   ;==>_set_Add

; #FUNCTION# ======================================================================================
; Name ..........: _set_ToArray()
; Description ...: convert a set into an array
; Syntax ........: _set_ToArray(ByRef $o_Set)
; Parameters ....: ByRef $o_Set - the set
; Return values .: Success: a 1D zero-based array filled with the set elements
;                  Failure: Set @error = 1 : $o_Set is not a correct set type
; Author ........: AspirinJunkie
; Related .......: __set_IsSet
; Example .......: Yes
;                  $a_Array = _set_ToArray($o_ExampleSet)
;                  _ArrayDisplay($a_Array, "converted array")
; =================================================================================================
Func _set_ToArray(ByRef $o_Set)
	If Not __set_IsSet($o_Set) Then Return SetError(1)

	Local $a_Ret[$o_Set.Count()], $i = 0
	For $o_Key In $o_Set
		$a_Ret[$i] = $o_Key
		$i += 1
	Next
	Return $a_Ret
EndFunc   ;==>_set_ToArray

; #FUNCTION# ======================================================================================
; Name ..........: _set_Display()
; Description ...: display a set variable like _ArrayDisplay
; Syntax ........: _set_Display(ByRef $o_Set, Const[ $s_Title = ""])
; Parameters ....: ByRef $o_Set   - the set
;                  Const $s_Title - [optional] the title for the window (default:"")
; Author ........: AspirinJunkie
; =================================================================================================
Func _set_Display(ByRef $o_Set, Const $s_Title = "")
	Local $a_Set = _set_ToArray($o_Set)
	_ArrayDisplay($a_Set, $s_Title, "", 64, Default, "value")
EndFunc   ;==>_set_Display
#EndRegion elementary set functions

#Region little helpers
; #FUNCTION# ======================================================================================
; Name ..........: __set_CloneDic()
; Description ...: creates a clone from a dictionary-object
; Syntax ........: __set_CloneDic(ByRef $o_Dic)
; Parameters ....: ByRef $o_Dic - the dictionary which should be cloned
; Author ........: AspirinJunkie
; =================================================================================================
Func __set_CloneDic(ByRef $o_Dic)
	Local $o_Ret = ObjCreate("Scripting.Dictionary")
	For $o_Key In $o_Dic
		$o_Ret($o_Key) = $o_Dic($o_Key)
	Next
	Return $o_Ret
EndFunc   ;==>__set_CloneDic

; #FUNCTION# ======================================================================================
; Name ..........: __set_IsSet()
; Description ...: check if a variable is a correct set-variable
; Syntax ........: __set_IsSet($o_Set)
; Parameters ....: $o_Set - the variable which should be checked
; Return values .: True if variable is set; False if not
; Author ........: AspirinJunkie
; =================================================================================================
Func __set_IsSet($o_Set)
	Return ObjName($o_Set) == "Dictionary"
EndFunc   ;==>__set_IsSet
#EndRegion little helpers
