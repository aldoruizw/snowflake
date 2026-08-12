# 🚀 Creating a dbt Project with Snowflake & GitHub

This guide shows you how to create a **dbt** project connected to **Snowflake**, and version-control it with **GitHub**.  
Perfect for analytics engineering setups! 🛠️

---

## 📋 Prerequisites
Before you start, make sure you have:
- ❄️ **Snowflake** account + credentials (role, warehouse, database, schema)
- 🐙 **GitHub** account + an empty repository for your project

---

## 1️⃣ Create the dbt Project

1. Go to **Account Settings** in your dbt account.📸
<img width="702" height="123" alt="image" src="https://github.com/user-attachments/assets/a2bac6c1-46f2-4e09-b0e4-258321f11688" />


2. Go to **Connections** and then select **+ New Connection**.
<img width="1585" height="364" alt="image" src="https://github.com/user-attachments/assets/57dfcb86-e2b6-401e-84ea-68cd2dd3d5f3" />


3. Select **Snowflake** as the adapter and enter your Snowflake account details:
   - **Account Identifier** (e.g., `SGIWCQE-RW77852`)
   - **Database**
   - **Warehouse**
   - **Role**
<img width="1269" height="1140" alt="image" src="https://github.com/user-attachments/assets/ef03f0e4-97d9-4c9b-a2f5-bfc5917a2432" />


4. Go back to **Account Settings**, select **Projects** and then **+ New Project**.
<img width="1596" height="229" alt="image" src="https://github.com/user-attachments/assets/4c2ac6bf-0f26-4352-85d1-84e757a79063" />


5. Add a project name.
<img width="1499" height="511" alt="image" src="https://github.com/user-attachments/assets/a8012146-47f7-4d5a-b643-47b1dcbb7048" />


6. Select the connection created in step 3.
<img width="1427" height="387" alt="image" src="https://github.com/user-attachments/assets/97926b14-aabb-4df3-8b2e-fcf2d04c3f6b" />


7. Add your credentials and then **Test** the connection.
<img width="1355" height="1061" alt="image" src="https://github.com/user-attachments/assets/1e6443b1-e461-41e2-89ef-418f50e39465" />


8. Select **GitHub** and then **Connect GitHub Account**.
<img width="1437" height="560" alt="image" src="https://github.com/user-attachments/assets/ac23c97d-b955-4107-8c28-163b9730d16f" />


9. You will be redirected to your GitHub account, you have to give access to your repository.
<img width="1162" height="911" alt="image" src="https://github.com/user-attachments/assets/a2663a3f-44b8-454d-93be-2f09b75467e1" />


10. Select your repository.
<img width="1418" height="682" alt="image" src="https://github.com/user-attachments/assets/08a48c48-a64c-4fb6-aa5f-d0d64efe4e9f" />


11. Select **Start developing in the Studio**.
<img width="975" height="803" alt="image" src="https://github.com/user-attachments/assets/0e4cd84a-0987-496a-b5d3-9dcffb622183" />


12. Select **Initialize dbt project**.
<img width="652" height="442" alt="image" src="https://github.com/user-attachments/assets/38bb805a-5e4e-4a56-9123-8d43d8d234ac" />


13. Select **Commit to new branch**.
<img width="623" height="333" alt="image" src="https://github.com/user-attachments/assets/0985ea26-e054-4196-99cb-d8289e1483f1" />


14. Add a commit message and then select **Commit Changes**.
<img width="614" height="266" alt="image" src="https://github.com/user-attachments/assets/fa2ecd8f-f4ec-4ca3-8d13-cc3b1eb41766" />


15. You can find the changes in your repository.
<img width="1892" height="1060" alt="image" src="https://github.com/user-attachments/assets/be4cf45b-9856-42e6-9dc0-a7eca1d9a430" />


## 2️⃣ Run Your First Model

1. Run:

```bash
dbt run
```
<img width="1862" height="748" alt="image" src="https://github.com/user-attachments/assets/68050ffe-b5dd-4d1c-aaa0-1eed00cc239f" />


2. You will find the objects in Snowflake.
<img width="735" height="468" alt="image" src="https://github.com/user-attachments/assets/ef2b6478-bf91-404f-9b69-c9544943cd45" />


---

## 📚 Resources
- 📄 [dbt and Snowflake for Admins](https://learn.getdbt.com/learn/course/dbt-cloud-and-snowflake-for-admins/)
