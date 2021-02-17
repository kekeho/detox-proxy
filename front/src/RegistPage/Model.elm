module RegistPage.Model exposing (..)


type alias RegistPageModel =
    { username: String
    , email: String
    , password: String
    , teamOfServiceAccept: Bool
    }


initModel : RegistPageModel
initModel =
    RegistPageModel
        ""
        ""
        ""
        False
