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

````
git clone https://github.com/settlemint/cocacolademo.git temp 

mv temp/.git project/.git

rm -rf temp

cd project 

git remote add origin https://github.com/settlemint/cocacolademo.git

git pull origin main
````

