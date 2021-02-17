module RegistPage.View exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)

view: (String, List (Html msg))
view =
    ( "registpage"
    , [ introductionView
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
            ++ [ confirmTeamOfServiceView
               , input [ type_ "submit", value "登録" ] [] 
               ]
            )
        ]


registFieldView : String -> String -> String -> Html msg
registFieldView formId formType labelStr =
    div [ class "form-column" ]
        [ label [ for formId ] [ text labelStr ]
        , input [ type_ formType, id formId ] []
        ]


introductionView : Html msg
introductionView =
    div [ class "introduction" ]
        [ h1 [] 
            [ text "バランスの取れた デジタルライフへ" ]
        , introductionSection "登録は簡単"
            [ p []
                [ text "フォームに情報を入力して登録ボタンを押したら、メールで認証するだけ。" ]
            , p []
                [ text "すぐにアクセス制御を設定して、数分後には健康的な生活への第一歩を踏み出すことができます。" ]
            ]
        , introductionSection "ユーザーのプライバシーを保護"
            [ p []
                [ text "detox-proxyを使えば、接続先のWEBサービスに対し、ユーザーのIPアドレスなどの個人情報を隠すことができます。"]
            ]
        ]


introductionSection : String -> List (Html msg) -> Html msg
introductionSection sectionTitle contents =
    div [ class "intro-section" ]
        (h2 [] [ text sectionTitle ] :: contents)


confirmTeamOfServiceView : Html msg
confirmTeamOfServiceView =
    p [ class "team-of-service" ] 
        [ input [ type_ "checkbox", id "teamofservice" ] [ ]
        , label [ for "teamofservice" ] 
            [ a [ href "/docs/teamofservice", target "_blank" ]  [ text "利用規約" ]
            , text "に同意"
            ]
        ]
