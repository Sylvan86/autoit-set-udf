At first, the topic sounds frightening and you ask yourself: why do I need something like that?
At second glance, however, questions that can be solved effectively with set operations often appear here in the forum.
Questions like "all elements which occur in Array1 as well as in Array2" are examples for such problems.

This UDF therefore provides a set data type and brings the corresponding mathematical functions (union, intersection, difference, symmetric difference).
To stand out a bit from the crowd, the UDF offers a function which can directly solve complex set algebra expressions like A∪B-(B∩(A∪A)∪C).

If you detach yourself a bit from the mathematical theory and look at the practice, you will surely find a useful application for this.

How does it work? - Here is a big example:

```AutoIt
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
```