module CallbackHell (main) where
import Prelude
import Control.Monad.Aff
import Network.HTTP.Affjax (get)
import Control.Monad.Eff.Console (log)
import Control.Monad.Eff.Class (liftEff)

main = launchAff $ do
  res1 <- get "http://localhost:3000/help"
  liftEff $ log $ "GET /help response: " ++ res1.response
  res2 <- get "http://localhost:3000/list"
  liftEff $ log $ "GET /list response: " ++ res2.response
