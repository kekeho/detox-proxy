module LoginPage.Model exposing (..)
import Http

type alias LoginPageModel =
    { email: String
    , password: String
    , remember: Bool
    , result: Maybe (Result Http.Error ())
    }


initLoginPageModel : LoginPageModel
initLoginPageModel =
    LoginPageModel
        "" "" True Nothing
