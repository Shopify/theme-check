# How to correct code with Code Actions

If you're trying to read the [Language Server Protocol(LSP) reference][lsp] or the code directly to figure out what's going on, you might have a hard time.

Let this document serve as an overview of what's going on with all those [CodeActionProviders](/lib/theme_check/language_server/code_action_provider.rb) and [ExecuteCommandProviders](/lib/theme_check/language_server/execute_command_provider.rb).

## Some definitions

### Code Action

A [Code Action][lspcodeaction] is the LSP concept for "stuff you might want to do on the code." Think refactoring, running tests, fixing lint errors, etc.

In VS Code, you might see those on right clicks:

In the command palette:

Or as keyboard shortcuts:

<details>
  <summary>Interface</summary>

  ```ts
  interface CodeAction {
    title: string; // UI string, human readable for the action
    kind?: CodeActionKind; // OPTIONAL, for filtering
    diagnostics?: Diagnostic[]; // The diagnostics that the action SOLVES.
    isPreferred?: boolean; // Are used by auto fix and can be targetted by keybindings.
    // Shown as faded out in the code action menu when the user request a more specific type of code action
    disabled?: {
      reason: string;
    },

    // if both edit and command are present, edit is run first then command.
    // I think edit is used so the client performs the change, wheras the command
    // would be done by the server
    edit?: WorkspaceEdit; // what this action does ??!!
    command?: Command; // the command that it executes
    data?: any; // sent from the CodeAction to the codeAction/resolve.
  }

  interface Command {
    title: string; // Title of the command, like `save`
    command: string; // id
    arguments?: any[]
  }
  ```
</details>

#### Flow overview

1. The client (VS Code, vim, etc.) sends a request to the server asking for code actions at the current location (file path + character range). 
2. The server (that's us) responds with an array of CodeAction for that location.
3. The client stores those actions and might show some of them in menus.

### Commands

[Commands][lspcommand] are methods that the client can trigger via the Client->Server `workspace/executeCommand` request. They can be literally anything. Think of them as function calls made by the client.

<details>
  <summary>Interface</summary>

  ```ts
  interface Command {
    title: string; // Title of the command, like `save`
    command: string; // id
    arguments?: any[]
  }
  ```
</details>

#### Flow overview

1. Command and arguments are in every `CodeAction`.
2. The user selects a code action to execute.
3. The client sends a `workspace/executeCommand` request to the server with arguments.
4. The server executes the command.

## How we fix code with Code Actions and Commands

We define a couple of providers.

- Two `CodeActionProvider`:
  1. [`QuickFixCodeActionProvider`](/lib/theme_check/language_server/code_action_providers/quickfix_code_action_provider.rb) - This one provides code actions that fix _one_ diagnostic. 
  2. [`SourceFixAllCodeActionProvider`](/lib/theme_check/language_server/code_action_providers/source_fix_all_code_action_provider.rb) - This one provides code actions that fix _all diagnostics in the current file_.
- One `ExecuteCommandProvider`:
  1. [`CorrectionExecuteCommandProvider`](/lib/theme_check/language_server/execute_command_providers/correction_execute_command_provider.rb) - This one takes a list of diagnostics as arguments, turns them into a WorkspaceEdit (the LSP construct for code edits) and tries to apply them with the server->client `workspace/applyEdit` request. The client then responds with the status of the apply edit (applied?).

## The entire flow

![entire flow](/docs/code-action-flow.png)

1. The Client asks the server for code actions for the current file and character range.
2. The Server responds with a list of code actions that can be applied for this location and character range. (`quickfix` and `source.fixAll`)
3. ...Wait for user input...
4. The User selects one of the code actions
5. The client sends a `workspace/executeCommand` request to the server for this code action.
6. The server figures out the workspace edit for the command and arguments.
7. The server sends a `workspace/applyEdit` request for the file modifications that would fix the diagnostics.
8. The client responds with the status of the applyEdit.
9. The server cleans up its internal representation of the diagnostics and updates the client with the latest diagnostics.
11. The server responds to the `workspace/executeCommand` request.

[lsp]: https://microsoft.github.io/language-server-protocol/specification
[lspcodeaction]: https://microsoft.github.io/language-server-protocol/specification#textDocument_codeAction
[lspexecutecommand]: https://microsoft.github.io/language-server-protocol/specification#workspace_executeCommand
