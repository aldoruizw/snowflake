# 🚀 Set Up Folders by Domain
1. Create a new branch **feat/setup-file-structure2**.
2. Go to **models** folder.
    1. Create **finance** folder and create a file **.gitkeep**.
    2. Create **marketing** folder and create a file **.gitkeep**.
    3. Create **sales** folder and create a file **.gitkeep**.
3. Modify the file **dbt_project.yml**.
    1. Rename the project name from **my_new_project** to **internal_analytics** (Lines 5 and 39).
    2. Delete lines 40, 41, and 42.
    3. Save the file.
4. Go to **Version control**.
    1. Select **Commit and sync**.
    2. Add the commit message **setup file structure**.
    3. Select **Commit Changes**.
    4. Select **Create a pull request on GitHub**.
    5. In GitHub.
        1. Add comment **adds our three departments**.
        2. Select **Create pull request**.
        3. Select **Merge pull request**.
        4. Select **Confirm merge**.
5. Go back to dbt Studio.
    1. Expand the menu in **Version control** next to **Create a pull request on GitHub** and select **Refresh git state**.
    2. Select **Pull from “main”**.
    3. Select **Change branch** and then select the **main** branch.
    4. Select Pull from remote.
