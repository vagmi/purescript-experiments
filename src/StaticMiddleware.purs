module StaticMiddleware (publicMiddleware, bowerMiddleware) where
import Prelude hiding (apply)
import Data.Function
import Node.Express.Types
import Node.Express.App

foreign import publicMiddleware :: Fn3 Request Response (ExpressM Unit) (ExpressM Unit)
foreign import bowerMiddleware :: Fn3 Request Response (ExpressM Unit) (ExpressM Unit)
