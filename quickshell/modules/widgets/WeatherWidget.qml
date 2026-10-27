import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs
import qs.modules.components
import qs.modules.services

WidgetLayout {
    // Skip today (index 0) - it's already shown as the current conditions above.
    //ListView {
    //    id: hourlyList
    //    Layout.fillWidth: true
    //    Layout.preferredHeight: Config.weatherHourlyRowHeight
    //    visible: root.hourlyForecast.length > 0
    //    orientation: ListView.Horizontal
    //    clip: true
    //    spacing: Config.spacingLarge
    //    boundsBehavior: Flickable.StopAtBounds
    //    model: root.hourlyForecast
    //    delegate: ColumnLayout {
    //        required property var modelData
    //        width: Config.weatherHourlyRowHeight
    //        spacing: Config.appletSpacing
    //        Text {
    //            Layout.alignment: Qt.AlignHCenter
    //            text: modelData.hour
    //            font.family: Config.fontFamily
    //            font.pixelSize: root.captionFontSize
    //            color: Config.colSubtext
    //        }
    //        IconImage {
    //            Layout.alignment: Qt.AlignHCenter
    //            source: Quickshell.iconPath(root.weatherIconName(modelData.weatherCode), "weather-clear-symbolic")
    //            implicitSize: Config.iconSizeSmall
    //        }
    //        Text {
    //            Layout.alignment: Qt.AlignHCenter
    //            text: modelData.temp + "°"
    //            font.family: Config.fontFamily
    //            font.pixelSize: root.captionFontSize
    //            color: Config.colText
    //        }
    //    }
    //}

    id: root

    property real temperature: 0
    property int weatherCode: -1
    property bool loaded: false
    property var forecast: []
    property var hourlyForecast: []

    function weatherIconName(code) {
        if (code === 0)
            return "weather-clear-symbolic";

        if (code <= 3)
            return "weather-few-clouds-symbolic";

        if (code === 45 || code === 48)
            return "weather-fog-symbolic";

        if (code >= 51 && code <= 57)
            return "weather-showers-scattered-symbolic";

        if ((code >= 61 && code <= 67) || (code >= 80 && code <= 82))
            return "weather-showers-symbolic";

        if ((code >= 71 && code <= 77) || code === 85 || code === 86)
            return "weather-snow-symbolic";

        if (code >= 95)
            return "weather-storm-symbolic";

        return "weather-overcast-symbolic";
    }

    function weatherConditionText(code) {
        if (code === 0)
            return "Clear";

        if (code <= 3)
            return "Partly cloudy";

        if (code === 45 || code === 48)
            return "Fog";

        if (code >= 51 && code <= 57)
            return "Drizzle";

        if ((code >= 61 && code <= 67) || (code >= 80 && code <= 82))
            return "Rain";

        if ((code >= 71 && code <= 77) || code === 85 || code === 86)
            return "Snow";

        if (code >= 95)
            return "Thunderstorm";

        return "Overcast";
    }

    function refreshWeather() {
        if (!Location.loaded)
            return ;

        const url = `https://api.open-meteo.com/v1/forecast?temperature_unit=fahrenheit&latitude=${Location.latitude}&longitude=${Location.longitude}&current_weather=true&daily=weathercode,temperature_2m_max,temperature_2m_min&hourly=temperature_2m,weathercode&timezone=auto&forecast_days=${Config.weatherForecastDays}`;
        Http.getJson(url, (data) => {
            if (data.current_weather) {
                root.temperature = data.current_weather.temperature;
                root.weatherCode = data.current_weather.weathercode;
                root.loaded = true;
            }
            if (data.daily)
                root.forecast = data.daily.time.slice(1).map((date, i) => {
                return ({
                    "day": Qt.formatDate(new Date(date), "ddd"),
                    "weatherCode": data.daily.weathercode[i + 1],
                    "high": Math.round(data.daily.temperature_2m_max[i + 1]),
                    "low": Math.round(data.daily.temperature_2m_min[i + 1])
                });
            });

            if (data.hourly) {
                // open-meteo's hourly series starts at midnight today, so skip past
                // whatever's already elapsed and show the next weatherHourlyCount hours.
                const now = new Date();
                const startIndex = data.hourly.time.findIndex((t) => {
                    return new Date(t) >= now;
                });
                const from = startIndex === -1 ? 0 : startIndex;
                root.hourlyForecast = data.hourly.time.slice(from, from + Config.weatherHourlyCount).map((time, i) => {
                    return ({
                        "hour": Qt.formatDateTime(new Date(time), "h AP"),
                        "weatherCode": data.hourly.weathercode[from + i],
                        "temp": Math.round(data.hourly.temperature_2m[from + i])
                    });
                });
            }
        }, "weather");
    }

    Component.onCompleted: refreshWeather()

    Connections {
        function onLoadedChanged() {
            root.refreshWeather();
        }

        target: Location
    }

    Timer {
        interval: Config.weatherRefreshIntervalMs
        running: true
        repeat: true
        onTriggered: root.refreshWeather()
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Config.spacingLarge

        IconImage {
            source: Quickshell.iconPath(root.weatherIconName(root.weatherCode), "weather-clear-symbolic")
            implicitSize: Config.weatherIconSizeLarge
            visible: root.loaded
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            Text {
                text: root.loaded ? Math.round(root.temperature) + "°F" : "Loading…"
                font.family: Config.fontFamily
                font.bold: true
                font.pixelSize: 48
                color: Config.colText
            }

            Text {
                text: root.loaded ? (root.weatherConditionText(root.weatherCode)) : "..."
                font.family: Config.fontFamily
                font.pixelSize: root.captionFontSize
                color: Config.colSubtext
            }

            Text {
                text: Location.cityName
                font.family: Config.fontFamily
                font.pixelSize: root.captionFontSize
                color: Config.colSubtext
            }

        }

    }

    RowLayout {
        Layout.fillWidth: true
        visible: root.forecast.length > 0
        spacing: Config.spacingSmall

        Repeater {
            model: root.forecast

            delegate: ColumnLayout {
                required property var modelData

                Layout.fillWidth: true
                spacing: Config.appletSpacing

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: modelData.day
                    font.family: Config.fontFamily
                    font.pixelSize: root.captionFontSize
                    color: Config.colSubtext
                }

                IconImage {
                    Layout.alignment: Qt.AlignHCenter
                    source: Quickshell.iconPath(root.weatherIconName(modelData.weatherCode), "weather-clear-symbolic")
                    implicitSize: Config.iconSizeMedium
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: modelData.high + "°/" + modelData.low + "°"
                    font.family: Config.fontFamily
                    font.pixelSize: root.captionFontSize
                    color: Config.colText
                }

            }

        }

    }

    // Soaks up leftover height when the box is resized taller than the content needs,
    // so content stays pinned to the top instead of ColumnLayout spreading it out.
    Item {
        Layout.fillHeight: true
    }

}
