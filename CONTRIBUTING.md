# How to Contribute

## Quickstart

1. Clone the repository
2. Install dependencies
   ```shell
   pnpm install
   ```
3. Make your changes and stage them
   ```shell
   git add .
   ```
4. Run the linters
   ```shell
   pnpm lint-staged
   ```
5. Commit your changes using the commit message format specified below
   ```shell
   git commit -m "fix: correct spelling of CHANGELOG"
   ```
6. Or, run the commit prompt, and follow the instructions
   ```shell
   pnpm commit
   ```

## Conventional Commits

This project requires commit messages to follow the [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) specification. This helps in generating a changelog and automating the release process.

### Examples

#### Commit message with description and breaking change footer
```
feat: allow provided config object to extend other configs

BREAKING CHANGE: `extends` key in config file is now used for extending other config files
```

#### Commit message with `!` to draw attention to breaking change
```
feat!: send an email to the customer when a product is shipped
```

#### Commit message with scope and `!` to draw attention to breaking change
```
feat(api)!: send an email to the customer when a product is shipped
```

#### Commit message with both `!` and BREAKING CHANGE footer
```
chore!: drop support for Node 6

BREAKING CHANGE: use JavaScript features not available in Node 6.
```

#### Commit message with no body
```
docs: correct spelling of CHANGELOG
```

#### Commit message with scope
```
feat(lang): add Polish language
```

#### Commit message with multi-paragraph body and multiple footers
```
fix: prevent racing of requests

Introduce a request id and a reference to latest request. Dismiss
incoming responses other than from latest request.

Remove timeouts which were used to mitigate the racing issue but are
obsolete now.

Reviewed-by: Z
Refs: #123
```
