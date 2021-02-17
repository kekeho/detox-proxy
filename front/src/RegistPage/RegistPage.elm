module RegistPage.RegistPage exposing (..)

import RegistPage.Model exposing (RegistPageModel, initModel)



type InputEvent
    = UserName String
    | Email String
    | Password String
    | TeamOfService Bool
    | SubmitForm


type RegistPageMsg
    = FormInput InputEvent


update : RegistPageMsg -> RegistPageModel -> (RegistPageModel, Cmd RegistPageMsg)
update msg model =
    case msg of
        FormInput event ->
            case event of
                UserName username ->
                    ( { model | username = username }
                    , Cmd.none
                    )
                
                Email email ->
                    ( { model | email = email }
                    , Cmd.none
                    )
                
                Password pw ->
                    ( { model | password = pw }
                    , Cmd.none
                    )
                
                TeamOfService v ->
                    ( { model | teamOfServiceAccept = v }
                    , Cmd.none
                    )
                
                SubmitForm ->
                    ( initModel
                    , Cmd.none
                    )
