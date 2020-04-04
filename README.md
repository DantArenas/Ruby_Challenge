# Ruby Challenge
**Memcached Server**

### Requirements
To run this project server, use your computer Terminal
1. Windows: CMD
2. MAC: Terminal

### Installing
First, we need to get the gems used in the project. To do this, open the computer terminal on both the server and client folders.
Then, type in the next command:
```
  bundle install
```

### Running the Server
Open a Terminal window and change to the **_server/lib_ folder directory**. Then use the following command line:
```
  ruby server.rb
```

If server launched ok, you will get this response:
```
  Server Up and Running [PORT: Port Number]
  WAITING FOR REQUESTS...
```
Each time a new Client is connected to the server, you should get a notification like this:
```
  New connection established! Now (number) clients :>
```


### Running the Client
With the **Server Running**, open a new Terminal window and change to the **_client/lib_ folder directory**. Then use the following command line:
```
  ruby client.rb
```

If client started ok, you will get this response:
```
  Server: Connection established with (client handler)
  Server: You may introduce commands now
```
After that, every time you type into the Terminal, you will receive an answer from the server, followed by a notification that you can keep on typing, as this:
```
Write your command
```

To **close** the client connection you can type in the word "*close*", just like that. If you finish the execution of the client, it will also notify the server, so it can close that connection and free up processing for a new client.

## Available commands

Next, a list of all commands available to the moment of this commit.

### Server Commands
#### Clients (command: "clients")
Response with the number of clients connected to the server.
#### Server Version (command: "server -v")
Response with the version of the server.
#### Close (command: "close")
Notifies and closes communication with the server. Also finishes the client execution.
#### Salute (command: "hello")
Literally a salute protocol, because of manners matters. Say hello to the server, and it will respond accordingly!
