module RegistPage.View exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)

view: (String, List (Html msg))
view =
    ( "registpage"
    , [ div [ class "introduction" ] [ text "introduction" ]
      , div [ class "regist" ]
        [ registFormView
        ]
      ]
    )



registFormView : Html msg
registFormView =
    let
        formColList =
            [ ("username", "text", "ユーザー名")
            , ("email", "email", "メールアドレス")
            , ("password", "password", "パスワード")
            ]
    in
    div [ class "regist-panel" ]
        [ h1 [] [ text "ユーザー登録" ]
        
        , Html.form [ ]
            ( List.map (\(i, t, l) -> registFieldView i t l) formColList
            ++ [ input [ type_ "submit", value "登録" ] [] ]
            )
        ]


registFieldView : String -> String -> String -> Html msg
registFieldView formId formType labelStr =
    div [ class "form-column" ]
        [ label [ for formId ] [ text labelStr ]
        , input [ type_ formType, id formId ] []
        ]


