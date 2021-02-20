module LoginPage.LoginPage exposing (..)

import LoginPage.Model exposing (LoginPageModel)


type InputEvent
    = Email String
    | Password String
    | Remember Bool
    | SubmitForm


type LoginPageMsg
    = FormInput InputEvent



update : LoginPageMsg -> LoginPageModel ->  ( LoginPageModel, Cmd LoginPageMsg )
update msg model =
    case msg of
        FormInput event ->
            case event of
                Email e ->
                    ( { model | email = e }
                    , Cmd.none 
                    )
                
                Password p ->
                    ( { model | password = p }
                    , Cmd.none
                    )
                
                Remember b ->
                    ( { model | remember = b }
                    , Cmd.none
                    )
                
                SubmitForm ->
                    ( model, Cmd.none )
                
