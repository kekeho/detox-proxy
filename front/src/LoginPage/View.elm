module LoginPage.View exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)


view: (String, List (Html msg))
view =
    ( "loginpage"
    , [ div [ class "login panel" ]
        [ h1 [] [ text "ログイン" ]
        , Html.form []
            [ loginFieldView "email" "email" "メールアドレス" True "" (class "dummy")
            , loginFieldView "password" "password" "パスワード" True "" (class "dummy")
            , p [ ] 
                [ input [ type_ "checkbox", id "remember" ] []
                , label [ for "remember" ] [ text "ログインを記憶する"]  
                ]
            , input [ type_ "submit", value "ログイン" ] []
            ]
        ]
      ]
    )


loginFieldView : String -> String -> String -> Bool -> String -> Attribute msg -> Html msg
loginFieldView formId formType labelStr req val attr =
    div [ class "form-column" ]
        [ label [ for formId ] [ text labelStr ]
        , input [ type_ formType, id formId, required req, value val,attr ] []
        ]
