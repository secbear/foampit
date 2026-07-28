package prototype

_left:  *"workspace-edit-offline" | #ProfileName
_right: *"workspace-live-development" | #ProfileName

output: _left & _right
