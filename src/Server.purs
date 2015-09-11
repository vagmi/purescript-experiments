module Server where

import Prelude hiding (apply)
import Data.Maybe
import Data.Function
import Data.Array (range, zipWith, length)
import Data.Foreign.EasyFFI
import Control.Monad.Eff
import Control.Monad.Eff.Class
import Control.Monad.Eff.Console (log)
import Control.Monad.Eff.Exception
import Control.Monad.ST
import Node.Express.Types
import Node.Express.App
import Node.Express.Handler

import StaticMiddleware

-- Pretend for now that this is our cool database (:
todos :: Array Todo
todos = []

type Todo = { desc :: String, isDone :: Boolean }
type IndexedTodo = { id :: Number, desc :: String, isDone :: Boolean }

addTodo :: forall e. Array Todo -> Todo -> Eff e Number
addTodo =
    unsafeForeignFunction ["todos", "todo", ""]
    "todos.push(todo) - 1"

updateTodo :: forall e. Array Todo -> Number -> String -> Eff e Unit
updateTodo =
    unsafeForeignProcedure ["todos", "id", "newDesc", ""]
    "(todos[id] || {}).desc = newDesc;"

deleteTodo :: forall e. Array Todo -> Number -> Eff e Unit
deleteTodo =
    unsafeForeignProcedure ["todos", "id", ""]
    "todos.splice(id, 1);"

setDone :: forall e. Array Todo -> Number -> Eff e Unit
setDone =
    unsafeForeignProcedure ["todos", "id", ""]
    "(todos[id] || {}).isDone = true;"

getTodosWithIndexes :: forall e. Array Todo -> Eff e (Array IndexedTodo)
getTodosWithIndexes =
    unsafeForeignFunction ["todos", ""]
    "todos.map(function(t,i) { return { id: i, desc: t.desc, isDone: t.isDone }; });"

parseNumber :: String -> Number
parseNumber = unsafeForeignFunction ["str"] "parseInt(str);"


logger :: Handler
logger = do
    url <- getOriginalUrl
    liftEff $ log (">>> " ++ url)
    next

errorHandler :: Error -> Handler
errorHandler err = do
    setStatus 400
    sendJson {error: message err}

help = { name: "Todo example"
       , howToUse:
            { listTodos: "/list"
            , createTodo: "/create?desc=Do+something"
            , doTodo: "/done/:id"
            , updateTodo: "/update/:id?desc=Do+something+else"
            , deleteTodo: "/delete/:id"
            }
       }

helpHandler :: Handler
helpHandler = sendJson help

listTodosHandler :: Handler
listTodosHandler = do
    indexedTodos <- liftEff $ getTodosWithIndexes todos
    sendJson indexedTodos

createTodoHandler :: Handler
createTodoHandler = do
    descParam <- getQueryParam "desc"
    case descParam of
        Nothing -> nextThrow $ error "Description is required"
        Just desc -> do
            newId <- liftEff $ addTodo todos { desc: desc, isDone: false }
            sendJson {status: "Created", id: newId}

updateTodoHandler :: Handler
updateTodoHandler = do
    idParam <- getRouteParam "id"
    descParam <- getQueryParam "desc"
    case [idParam, descParam] of
        [Just id, Just desc] -> do
            liftEff $ updateTodo todos (parseNumber id) desc
            sendJson {status: "Updated"}
        _ -> nextThrow $ error "Id and Description are required"

deleteTodoHandler :: Handler
deleteTodoHandler = do
    idParam <- getRouteParam "id"
    case idParam of
        Nothing -> nextThrow $ error "Id is required"
        Just id -> do
            liftEff $ deleteTodo todos (parseNumber id)
            sendJson {status: "Deleted"}

doTodoHandler :: Handler
doTodoHandler = do
    idParam <- getRouteParam "id"
    case idParam of
        Nothing -> nextThrow $ error "Id is required"
        Just id -> do
            liftEff $ setDone todos (parseNumber id)
            sendJson {status: "Done"}

appSetup :: App
appSetup = do
    liftEff $ log "Setting up"
    setProp "json spaces" 4.0
    use logger
    useExternal publicMiddleware
    useExternal bowerMiddleware
    get "/help" helpHandler
    get "/list" listTodosHandler
    get "/create" createTodoHandler
    get "/update/:id" updateTodoHandler
    get "/delete/:id" deleteTodoHandler
    get "/done/:id" doTodoHandler
    useOnError errorHandler

main :: forall e. Eff (express :: Express | e) Unit
main = do
    port <- unsafeForeignFunction [""] "process.env.PORT || 3000"
    listenHttp appSetup port \_ ->
        log $ "Listening on " ++ show port
