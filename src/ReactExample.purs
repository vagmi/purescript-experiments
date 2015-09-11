module ReactExample (main) where
import Prelude
import Data.Maybe.Unsafe (fromJust)
import Data.Nullable (toMaybe)
import Control.Monad.Eff

import qualified Thermite as T
import qualified Thermite.Action as T
import qualified React as R
import qualified React.DOM as RD
import qualified React.DOM.Props as RP
import qualified DOM as DOM
import qualified DOM.HTML as DOM
import qualified DOM.HTML.Document as DOM
import qualified DOM.HTML.Types as DOM
import qualified DOM.HTML.Window as DOM
import qualified DOM.Node.Types as DOM


data State = State {counter :: Int}
data Action = Increment | Decrement | Reset

initialState :: State
initialState = State { counter: 0 }

updateState :: Action -> State -> State
updateState Increment (State st) = State (st { counter = st.counter + 1})
updateState Decrement (State st) = State (st { counter = st.counter - 1})
updateState Reset _ = initialState

performAction :: T.PerformAction _ State _ Action
performAction _ action = T.modifyState (updateState action)

render :: T.Render _ State _ Action
render ctx (State st) _ _ =
  RD.div' [ RD.h1' [RD.text $ "Hello React"]
          , RD.p'  [RD.text $ show st.counter]
          , RD.button [RP.onClick \_ -> ctx Increment] [RD.text "increment"]
          , RD.button [RP.onClick \_ -> ctx Decrement] [RD.text "decrement"]
          , RD.button [RP.onClick \_ -> ctx Reset] [RD.text "reset"]]

spec :: T.Spec _ State _ Action
spec = T.simpleSpec initialState performAction render

body :: forall eff. Eff (dom :: DOM.DOM | eff) DOM.Element
body = do
  win <- DOM.window
  doc <- DOM.document win
  elm <- fromJust <$> toMaybe <$> DOM.body doc
  return $ DOM.htmlElementToElement elm

main = do
  let component = T.createClass spec
  body >>= R.render (R.createFactory component {})
