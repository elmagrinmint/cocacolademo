# Instructions

- Create a new deployment

- Delete the following folders: 
    -  Contracts
    -  Migrations
    -  Scripts
    -  Test
- Delete all the files at root 
- Open up a new terminal
- cd ..
- exec the below commands

git clone https://github.com/<<your_user_name>>/<<your_repo_name>>.git temp <br/>

mv temp/.git code/.git <br/>

rm -rf temp

cd project 

git remote add origin https://github.com/<<your_user_name>>/<<your_repo_name>>.git

git pull origin main


