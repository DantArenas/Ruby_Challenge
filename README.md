# Ruby Challenge
**Memcached Server**

### Requirements
To run this project server, use your computer Terminal
1. Windows: CMD
2. MAC: Terminal

### Installing
First, we need to get the gems used in the project. Currently the project doesn't use special gems. To do this, open the computer terminal on both the server and client folders.
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
  Server Up and Running [PORT: 8080]
  WAITING FOR REQUESTS...
```
Each time a new Client is connected to the server, you should get a notification like this:
```
  New connection established! Now (number) clients :>
```
**Note:** when the server execution stops, it will notify and close the connection of all the clients before shutting down, so they can stop the communication process, avoiding errors.

### Running the Client
With the **Server Running**, open a new Terminal window and change to the **_client/lib_ folder directory**. Then use the following command line:
```
  ruby client.rb
```

If client started ok, you will get this response:
```
  Server: Connection established with Client Handler ID: (id)
  Server: You are the client #(number)
  Server: You may introduce commands now
```
After that, every time you type into the Terminal, you will receive an answer from the server (except when specifying 'noreply'), followed by a notification that you can keep on typing, as this:
```
Write your command
```
The cliet has some useful methods and shortcuts to make easier for a human user to type commands. For example, the 'add_line_generator', wich sends to the server an 'Add' command, with the specific byte size of the data, so the user doesn't have to guess it. The shortcuts are listed below after the available commands.

To **close** the client connection you can type in the command "**_close_**" or "**_quit_**", just like that. If you finish the execution of the client, it will also notify the server, so it can close that connection and free up processing for a new client.

**Note:** when the client execution stops, it will notify the server before shutting down, so you can interrupt the execution at any moment without worries.

## Available commands

Next, a list of all commands available at the moment of this commit. If the user sends an Invalid command, the server will send a list of all the Valid commands divided in Retrieval and Storage commands.

**Storage Commands**

-> set   
-> add   
-> replace   
-> append   
-> prepend   
-> incr   
-> decr   
-> cas   

**Retrieval Commands**

-> get   
-> gets   
-> get_all   
-> delete   
-> flush_all   

**Other Commands**

-> quit   
-> close   
-> clients   
-> server -v   
-> hello   

### Server Commands
This commands are handled by the server it self.

**- Clients (command: "clients"):** Response with the number of clients connected to the server.
**- Server Version (command: "server -v"):** Response with the version of the server.
**- Close (command: "close"):** Notifies and closes communication with the server. Also finishes the client execution.
**- Salute (command: "hello"):** Literally a salute protocol, because of manners matters. Say hello to the server, and it will respond accordingly!

### Storage & Editing Commands
This commands store or edit stored data in the server. If the client does not want an answer, can add the argument 'noreply' just before the data.
**Note:** All Storage and Editing methods can receive 'noreply' as an argument. For simplicity purpose, only 'set' and 'add' commands include a 'noreply' example.

**- Set (command: "set"):** Storages data in the specified key. If the key already exists is overwritten.
```
set <key> <flags> <ttl> <bytes> [noreply] \r\nDATA\r\n

set 123 0 200 5 \r\nHello World\r\n # Example without 'noreply'
set 123 0 200 5 noreply \r\nHello World\r\n # Example with 'noreply'
```

**- Add (command: "set"):** Storages data in the specified key only if the key isn't registered yet.
```
add <key> <flags> <ttl> <bytes> [noreply] \r\nDATA\r\n

add 123 0 200 5 \r\nHello World\r\n # Example without 'noreply'
add 123 0 200 5 noreply \r\nHello World\r\n # Example with 'noreply'
```

**- Replace (command: "replace"):** Replaces the stored data in the specified key with the new one sent in the request. Key must exist.
```
replace <key> <flags> <ttl> <bytes> [noreply] \r\nDATA\r\n
replace 123 0 200 5 \r\nHello World\r\n # Example
```

**- Append (command: "append"):** Inserts the data sent in the recuest *after* the stored data in the specified key. Key must exist. Flags and expiration time (ttl) are ignored, as the protocol specifies.
```
apend <key> <flags> <ttl> <bytes> [noreply] \r\nDATA\r\n
apend 123 0 200 5 \r\nHello World\r\n # Example
```

**- Prepend (command: "prepend"):** Inserts the data sent in the recuest *before* the stored data in the specified key. Key must exist. Flags and expiration time (ttl) are ignored, as the protocol specifies.
```
prepend <key> <flags> <ttl> <bytes> [noreply] \r\nDATA\r\n
prepend 123 0 200 5 \r\nHello World\r\n # Example
```

**- Increment (command: "incr"):** If the specified key stored data is a numeric type, increments it's value by a given amaunt. Key must exist.
```
incr <key> <amaunt> [noreply] \r\n
incr 123 5 \r\n # Example: Increments 5
```

**- Decrement (command: "decr"):** If the specified key stored data is a numeric type, decrement it's value by a given amaunt. Key must exist.
```
decr <key> <amaunt> [noreply] \r\n
decr 123 5 \r\n # Example: Decrements 5
```

**- Check and Set (command: "cas"):** Is a check and set operation. If no one else has updated the cache since it was last fetched, store the given data.
```
cas <key> <flags> <ttl> <bytes> <cas_unique> [noreply] \r\nDATA\r\n
add 123 0 200 5 9999999999 \r\nHello World\r\n # Example
```

### Retrieval Commands
This retrives stored data from the server. All this requests have a response from the server, doesn't matter if it was successful or not. 'Delete' and 'flush_all' commands can edit cache entries by deleting them.

**- 'get' :** Returns the cache entry stored in the specified key, if it exists.
```
get <key> \r\n
get 123 \r\n # Example
```

**- 'gets' :** This single command line can retrieve multiple cache entries at the same time. The server searchs all the specified keys, and return the data if it exists. The response is a MULTI_LINE wich contains all the information. If a key is not found, is notified as NOT_FOUND. Invalid keys are ignored by the server, so it doesn't affect valid retrieval requests.
```
gets <key_1> <key_2> .. <key_n>  \r\n
gets 123 456 789 \r\n # Example
```

**- 'get_all' :** This single command line retrieves all cache entries stored. The response is a MULTI_LINE wich contains all the information. This command wasn't specified by the protocol, but it's very useful on some occasions. Does not need any arguments.
```
get_all \r\n
```

**- 'delete' :** Deletes the cache entry stored in the specified key, if it exists.
```
delete <key> \r\n
delete 123 \r\n # Example
```

**- 'flush_all' :** This command deletes all cache entries stored. Can specify an optional timelapse after wich all data will be purged. If no timelapse is specified, data purge will happen immediatly.
```
flush_all \r\n
```
## Client shortcuts
This commands are only available in the client class, and ere created to make easier typing commands into the terminal.

**- add:** Creates a default line with the needed args for the 'add' command, with <flags> = 0 and <ttl> = 300. After typing the shortcut 'add', the client service will ask the user to type the data to send. When the user is ready to send the request,  it can use the ENTER key.
```
add
Write the data u want to send....
DATA
# --> Push the ENTER key
```

**- tigres:** Types a short phrase: "Tres tristes tigres". Works as a short Lorem Ipsum. It's very useful combined with the 'add' shortcut.

**- multi:** This shortcut sends 5 different 'add' request to the server, with a delay of 0.3 seconds between each one. This gives time to the server for answering each request. After the 'add' commands, a 'gets' command is used to retrieve the information of those 5 specific keys, plus other 3 keys that are not stored. Here is a demo of how it looks like.

```
multi
shortcut ussed... sending: add 123 0 300 13 \r\nHabia una vez\r\n

STORED [key: 123, data: Habia una vez]
Write your command
shortcut ussed... sending: add 456 0 300 11 \r\nuna Iguana,\r\n
STORED [key: 456, data: una Iguana,]
Write your command
shortcut ussed... sending: add 112 0 300 22 \r\njunto al rio magdalena\r\n
STORED [key: 112, data: junto al rio magdalena]
Write your command
shortcut ussed... sending: gets 123 456 789 101 112 100 200 300

ONLY_FOUND -----------------
FOUND [key: 123, data: Habia una vez]
FOUND [key: 456, data: una Iguana,]
FOUND [key: 789, data: con una ruana de lana,]
FOUND [key: 101, data: peinandose la melena]
FOUND [key: 112, data: junto al rio magdalena]
NOT_FOUND [key: 100]
NOT_FOUND [key: 200]
NOT_FOUND [key: 300]
END
Write your command
```

## TODO

Here is a list of the following steps of the development:

1. Retrieval commands 'gat', 'gats', 'stats'
2. Storage commands 'verbosity'
3. Send object through server as JSon
4. Implement Flags
5. Ensure byte length fits specific data length
