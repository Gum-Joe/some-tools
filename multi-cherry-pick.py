import subprocess

# Define a list of pairs (branch_name, list_of_commit_shas)
branch_commit_pairs = [
    # ("themeing-ui-fixes-01-select-borders", ["bcf3ca7157d1f19dc0d8be06731db3e67edd0781"]),
    ("themeing-ui-fixes-02-exercise-buttons", ["6834366a6253a0c994e8db63eff297c43b9ea480i", "6e9d4f4eac61ef64f488a18d079b446f47560fd8"]),
    ("themeing-ui-fixes-03-dialogs", ["72979579ca08dbe060d82a6673f322424b3a6bba", "34dc1e51101caf650d4510c9f015737452d8e553", "618da286cf7c2143b6594823177394ef4cf69f89"]),
    ("themeing-ui-fixes-04-exercise-staff", ["8090af6801e4161afff5fc831a224e5acc4f5f21", "5698169ab5c099b7d33e752bb626d90e596c74c9", "165573fdd7f35b18e1afea087bf49b7c5a8f9da4"]),
    ("themeing-ui-fixes-05-delete-button", ["5f6752fc859ed7706478b06e43dccdc8a8adeb9b"]),
    ("themeing-ui-fixes-06-game", ["41087c33b43b11855ed3740abf628b27c42ab42b"]),
    ("themeing-ui-fixes-07-tables", ["04bbbbca6466369e939c1c47cf7519e49610b544"])
]

# Function to execute Git commands
def run_git_command(command):
    print(f"$ {command}")
    return subprocess.run(command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)

# Function to create a new branch, cherry-pick commits, and push to remote
def create_and_publish_branch(branch_name, commit_shas):
    # Switch to master branch
    run_git_command("git checkout master")

    # Create a new branch
    run_git_command(f"git checkout -b {branch_name}")

    # Cherry-pick each commit
    for sha in commit_shas:
        result = run_git_command(f"git cherry-pick {sha}")

        # Check for cherry-pick errors
        if result.returncode != 0:
            print(f"Error cherry-picking commit {sha}. Aborting.")
            run_git_command("git cherry-pick --abort")
            return

    # Push the branch to the remote
    run_git_command(f"git push --set-upstream origin {branch_name}")

# Loop through the list of branch-commit pairs
for branch_name, commit_shas in branch_commit_pairs:
    print(f"Creating and publishing branch: {branch_name}")
    create_and_publish_branch(branch_name, commit_shas)

print("Done.")

