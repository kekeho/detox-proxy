module View exposing (..)


import Html exposing (..)
import Html.Attributes exposing (..)


headerView: Html msg
headerView =
    header []
        [ a [ href "/" ]
            [ div [ class "logo" ]
                [ text "detox-proxy" ]
            ]
        ]


footerView: Html msg
footerView =
    footer []
        [ div [ class "logo" ] [ text "detox-proxy" ]
        , div [ class "github" ]
            [ div [] [ text "GitHub" ]
            , a [ href "https://github.com/kekeho/detox-proxy"]
                [ text "kekeho/detox-proxy" ]
            ]
        , div [ class "contact" ]
            [ text "made by kekeho."
            , ul []
                [ li [ ]
                    [ a [ href "https://github.com/kekeho" ] [ text "@kekeho" ] ]
                , li [ ]
                    [ a [ href "https://twitter.com/k3k3h0" ] [ text "@k3k3h0" ] ]

                ]
            ]
        ]


notFoundView: (String, List (Html msg))
notFoundView =
    ( "notfoundpage"
    , [ div [ class "message" ]
        [ text "404 not found" ]
      ]
    )
