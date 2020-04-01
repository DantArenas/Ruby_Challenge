# Ruby Challenge
**Memcached Server**

### Requirements
To run this project server, use your computer Terminal
1. Windows: CMD
2. MAC: Terminal

### Installing
First, we need to get the gems used in the projecto. To do this, open the computer terminal on both the server and client folders.
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

**Note:** Closing the server will close all client connections.

### Running the Client
Open a Terminal window and change to the **_client/lib_ folder directory**. Then use the following command line:
```
  ruby client.rb
```

If client started ok, you will get this response:
```
  Write your command
```

To **close** the client connection you con type in the word "*close*", just like that.
