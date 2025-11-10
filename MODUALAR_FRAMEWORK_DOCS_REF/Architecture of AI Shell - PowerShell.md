https://learn.microsoft.com/en-us/powershell/module/ make your agent “look in the PowerShell Gallery first” and only then decide whether to write new code.

# How your agent should search the Gallery (no code)

## 1) Prefer the official discovery cmdlets

Microsoft’s discovery layer lives in two places:

* **PSResourceGet (new)** — use **Find-PSResource** to search any registered repository (including the PowerShell Gallery). It returns rich package metadata (name, version, tags, authors, dependencies, etc.) your agent can score. ([Microsoft Learn][1])
* **PowerShellGet (v3 shim / v2 classic)** — legacy discovery surface via **Find-Module**, **Find-Script**, and **Find-Command** (these v3 cmdlets proxy to PSResourceGet under the hood). Your agent can still call them conceptually if you’re standardizing on that surface. ([Microsoft Learn][2])

Why this matters: it gives your agent a structured, supported way to query “what already exists?” before inventing new scripts.

## 2) Know there’s also a plain HTTP option (if you’re not running PowerShell)

The PowerShell Gallery exposes a **NuGet feed**. You can query it via HTTP as a **NuGet v2 OData** endpoint (for example, the service root is `/api/v2`). This is handy for non-PowerShell runtimes (Python, Node, Go) inside your autonomous system. Just note that NuGet v2 is older/quirkier compared to v3. ([PowerShell Gallery][3])


AI Shell for PowerShell – An official, open-source framework that lets you register multiple AI “agents” and chat with them from PowerShell. Ships with agents for OpenAI and Azure OpenAI; you can add others. It’s not an LLM itself, but it’s built for PowerShell workflows

Get started with AI Shell in PowerShell
AI Shell was created to help command line users find the right commands to use, recover from errors, and better understand the commands and the output they produce. Follow along and walk through some examples to get started with AI Shell.

Starting AI Shell
Use the Start-AIShell command in the AI Shell module to open the sidecar experience in Windows Terminal. When AI Shell starts, it prompts you to choose an agent.

An animation showing Getting Started with AI Shell.

Using AI Shell
Before you can use the Azure OpenAI agent, you must create a configuration that includes your endpoint, API keys, and system prompt. Start AI Shell, select the agent, and run /agent config. Within the JSON config file that is opened you will have to provide your endpoint, deployment name, model version and API key. You can configure the system prompt property to better ground the model to your specific use cases, the default included is for a PowerShell expert. Additionally if you wish you use OpenAI you can configure the agent with just your API key from OpenAI in the commented out example in the JSON file.

The Azure agent is designed to bring the Copilot in Azure experience directly to your command line. It provides assistance for Azure CLI and Azure PowerShell commands. To use this agent, you need to sign into Azure using the az login command from Azure CLI.

Use AI Shell to interact with the agents
Use these sample queries with each agent.

Azure OpenAI Agent

"How do I create a text file named helloworld in PowerShell?"
"What is the difference between a switch and a parameter in PowerShell?"
How do I get the top 10 most CPU intensive processes on my computer?
Copilot in Azure Agent

"How do I create a new resource group with Azure CLI?"
"How can I list out the storage accounts I have in Azure PowerShell?"
"What is Application Insights?"
"How to create a web app with Azure CLI?"
Here's a quick demo showing the Azure Agent in action:

An animation showing Azure Agent in action.

Switching Agents
You can switch between agents using the @<agentName> syntax in your chat messages. For example,

An animation showing switching between two agents with the @ sign

You can also use a chat command to switch agents. For example, to switch to the openai-gpt agent, use /agent use openai-gpt.

Chat commands
By default, aish provides a base set of chat commands used to interact with the AI model. To get a list of commands, use the /help command in the chat session.

  Name       Description                                      Source
──────────────────────────────────────────────────────────────────────
  /agent     Command for agent management.                    Core
  /cls       Clear the screen.                                Core
  /code      Command to interact with the code generated.     Core
  /dislike   Dislike the last response and send feedback.     Core
  /exit      Exit the interactive session.                    Core
  /help      Show all available commands.                     Core
  /like      Like the last response and send feedback.        Core
  /refresh   Refresh the chat session.                        Core
  /render    Render a markdown file, for diagnosis purpose.   Core
  /retry     Regenerate a new response for the last query.    Core
Inserting code
When chatting with the agent, you can use the /code post command to automatically insert the code from the response into the working shell. This is the simplest way to quickly get the code you need to run in your shell. You can also use the hot key Ctrl+d, Ctrl+d to insert the code into the working shell.

An animation showing Inserting Code with AI Shell.

Key bindings for commands
AI Shell has key bindings for the /code command. They key bindings are currently hard-coded, but custom key bindings will be supported in a future release.

Key bindings	Command	Functionality
Ctrl+dCtrl+c	/code copy	Copy all the generated code snippets to clipboard
Ctrl+<n>	/code copy <n>	Copy the n-th generated code snippet to clipboard
Ctrl+dCtrl+d	/code post	Post all the generated code snippets to the connected application
Ctrl+d<n>	/code post <n>	Post the n-th generated code snippet to the connected application
Additionally, you can switch between the panes easier using the following keyboard shortcuts.

Key bindings	Functionality
Alt+RightArrow	Moves your cursor to the right AI Shell pane
Alt+LeftArrow	Moves your cursor to the left PowerShell pane
Resolving Errors
If you encounter an error in your working terminal, you can use the Resolve-Error cmdlet to send that error to the open AI Shell window for resolution. This command asks the AI model to help you resolve the error.

An animation showing Resolving Errors with AI Shell.

Invoking AI Shell
You can use the Invoke-AIShell cmdlet to send queries to the current agent in the open AI Shell window. This command allows you to interact with the AI model from your working terminal.

An animation using Invoke-AIShell.

Additional resources
Documentation

Install AI Shell - PowerShell

Learn how to install AI Shell on your system.

Get started with AI Shell - PowerShell

This article explains how to install and configure AI Shell, and get started chatting with an AI assistant.

AI Shell command reference - PowerShell

Learn about the command-line options and commands available in AI Shell.

What is AI Shell? - PowerShell

Learn about AI Shell, an interactive shell that provides a chat interface with language models.

OpenAI agent - PowerShell

Learn how to configure the OpenAI agent.

Copilot in Azure Agent - PowerShell

Learn how to use the Copilot in Azure agent in AI Shell.

Architecture of AI Shell - PowerShell

This article explains the architecture of AI Shell and API required to support agents.









   OFFICAL TRPOSITYPRE https://github.com/PowerShell/AIShell

