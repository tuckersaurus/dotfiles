# Template Notes

## .github consistency

`project-repository` and `workspace-repository` both contain `.github/PULL_REQUEST_TEMPLATE.md`
and `.github/ISSUE_TEMPLATE/bug-report.md`. They are intentionally slightly different
(workspace templates reference devcontainer/Docker; project templates reference .NET/browser),
but should stay structurally consistent with each other.

When updating the format of either, update the other to match.
