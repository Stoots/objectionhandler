# Issue tracker: GitHub

Issues and specs live in GitHub Issues for `Stoots/objectionhandler`. Use the `gh` CLI; pass `--repo Stoots/objectionhandler` to issue and label commands so worktrees target this fork rather than its upstream.

## Conventions

- Create: `gh issue create --repo Stoots/objectionhandler --title "..." --body-file <file>`.
- Read: `gh issue view <number> --repo Stoots/objectionhandler --comments`; include the issue body and labels when gathering context.
- List: `gh issue list --repo Stoots/objectionhandler --state open --json number,title,body,labels,comments`; filter by the relevant state and labels.
- Comment: `gh issue comment <number> --repo Stoots/objectionhandler --body-file <file>`.
- Apply/remove labels: `gh issue edit <number> --repo Stoots/objectionhandler --add-label "..."` / `--remove-label "..."`.
- Close: `gh issue close <number> --repo Stoots/objectionhandler --comment "..."`.

## Publishing and fetching

When a skill says to publish a ticket, create a GitHub issue. When it says to fetch a ticket, read its full body, labels, and comments.

Publish approved tickets in dependency order. Use GitHub's native issue dependencies: POST `repos/Stoots/objectionhandler/issues/<blocked-number>/dependencies/blocked_by` with `issue_id` set to the blocker's numeric database ID, obtained from GET `repos/Stoots/objectionhandler/issues/<blocker-number>`. If dependencies are unavailable, include a `Blocked by: #<number>` section in the issue body. A ticket can start when all its blockers are closed.

## Pull requests as a triage surface

**PRs as a request surface: no.**

GitHub shares an issue/PR number space. Resolve an ambiguous number with `gh pr view <number> --repo Stoots/objectionhandler`; fall back to `gh issue view` if it is not a PR.
