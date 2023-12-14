load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")


def main(config):
    selected_team = config.get("selectedTeam", "COL")
    timezone = config.get("timezone", "America/Denver")

    # http://site.api.espn.com/apis/site/v2/sports/hockey/nhl/teams/COL/schedule
    url = "https://site.api.espn.com/apis/site/v2/sports/hockey/nhl/teams/%s/schedule" % selected_team
    res = http.get(url=url)
    if res.status_code != 200:
        fail("request to %s failed with status code: %d - %s" % (url, res.status_code, res.body()))

    schedule = json.decode(res.body())
    upcoming = get_next_2(schedule, selected_team, timezone)
    if len(upcoming) < 1:
        return []

    column_width = int(64 / len(upcoming))
    event_components = []
    for event_data in upcoming:
        component = render.Box(
            color=event_data["color"],
            width=column_width,
            height=32,
            child=render.Column(
                main_align="center",
                cross_align="center",
                children=[
                    render.Box(width=12, height=12,
                               child=render.Image(src=event_data["logo"], height=event_data["logo_size"],
                                                  width=event_data["logo_size"])),
                    render.Box(width=column_width - 4, height=6,
                               child=render.Text(content=event_data["matchup"], height=5, font="CG-pixel-3x5-mono")),
                    render.Box(width=column_width - 4, height=6,
                               child=render.Text(content=event_data["date"], height=5, font="CG-pixel-3x5-mono")),
                    render.Box(width=column_width - 4, height=6,
                               child=render.Text(content=event_data["time"], height=5, font="CG-pixel-3x5-mono")),
                ]
            )
        )
        event_components.append(component)

    return render.Root(
        child=render.Row(
            expanded=True,
            children=event_components
        )
    )


def get_next_2(schedule, team, timezone):
    upcoming = []
    for event in schedule["events"]:
        if len(upcoming) >= 2:
            return upcoming

        competition = event["competitions"][0]
        game_type = competition["status"]["type"]["state"]
        if game_type != "pre":
            continue

        home_team = competition["competitors"][0]["team"]["abbreviation"]
        if home_team != team:
            continue

        # This is a game we want to add to the upcoming list
        away_team = competition["competitors"][1]["team"]["abbreviation"]
        event_time = time.parse_time(event["date"], format="2006-01-02T15:04Z").in_location(timezone)
        away_logo_url = competition["competitors"][1]["team"]["logos"][3]["href"]

        event_data = {
            "matchup": "vs %s" % away_team,
            "date": event_time.format("1/2"),
            "time": event_time.format("3:04 PM")[:7],
            "logo": get_team_logo(away_logo_url),
            "logo_size": logo_size_map.get(away_team, 12),
            "color": get_team_color(away_team),
        }
        upcoming.append(event_data)
    return upcoming


def get_team_color(team):
    if team == "NSH":
        return "#041E42"
    if team == "BUF":
        return "#003087"

    url = "https://site.api.espn.com/apis/site/v2/sports/hockey/nhl/teams/%s" % team
    res = http.get(url=url)
    if res.status_code != 200:
        return "#000000"
    return json.decode(res.body())["team"]["color"]


def get_team_logo(logo_url):
    logo_url = logo_url.replace("https://a.espncdn.com/", "https://a.espncdn.com/combiner/i?img=", 36000) + "&h=50&w=50"
    res = http.get(url=logo_url)
    if res.status_code == 200:
        return res.body()
    fallback_logo_url = "https://i.ibb.co/5LMp8T1/transparent.png"
    return http.get(url=fallback_logo_url).body()


logo_size_map = {
    "ANA": 14,
    "ARI": 14,
    "CAR": 14,
    "CBJ": 14,
    "DAL": 14,
    "DET": 14,
    "MIN": 14,
    "NSH": 14,
    "SJ": 14,
    "SEA": 14,
    "TOR": 14,
}


def get_schema():
    return schema.Schema(
        version="1",
        fields=[
            schema.Text(
                id="timezone",
                name="Time Zone",
                desc="Location for which to display time.",
                icon="gear",
            ),
            schema.Dropdown(
                id="selectedTeam",
                name="Team",
                desc="The team to show upcoming games for.",
                icon="gear",
                default=teamOptions[7].value,
                options=teamOptions,
            ),
        ],
    )


teamOptions = [
    schema.Option(
        display="Anaheim Ducks",
        value="ANA",
    ),
    schema.Option(
        display="Arizona Coyotes",
        value="ARI",
    ),
    schema.Option(
        display="Boston Bruins",
        value="BOS",
    ),
    schema.Option(
        display="Buffalo Sabres",
        value="BUF",
    ),
    schema.Option(
        display="Calgary Flames",
        value="CGY",
    ),
    schema.Option(
        display="Carolina Hurricanes",
        value="CAR",
    ),
    schema.Option(
        display="Chicago Blackhawks",
        value="CHI",
    ),
    schema.Option(
        display="Colorado Avalanche",
        value="COL",
    ),
    schema.Option(
        display="Columbus Blue Jackets",
        value="CBJ",
    ),
    schema.Option(
        display="Dallas Stars",
        value="DAL",
    ),
    schema.Option(
        display="Detroit Red Wings",
        value="DET",
    ),
    schema.Option(
        display="Edmonton Oilers",
        value="EDM",
    ),
    schema.Option(
        display="Florida Panthers",
        value="FLA",
    ),
    schema.Option(
        display="Los Angeles Kings",
        value="LA",
    ),
    schema.Option(
        display="Minnesota Wild",
        value="MIN",
    ),
    schema.Option(
        display="Montreal Canadiens",
        value="MTL",
    ),
    schema.Option(
        display="Nashville Predators",
        value="NSH",
    ),
    schema.Option(
        display="New Jersey Devils",
        value="NJ",
    ),
    schema.Option(
        display="New York Islanders",
        value="NYI",
    ),
    schema.Option(
        display="New York Rangers",
        value="NYR",
    ),
    schema.Option(
        display="Ottawa Senators",
        value="OTT",
    ),
    schema.Option(
        display="Philadelphia Flyers",
        value="PHI",
    ),
    schema.Option(
        display="Pittsburgh Penguins",
        value="PIT",
    ),
    schema.Option(
        display="San Jose Sharks",
        value="SJ",
    ),
    schema.Option(
        display="Seattle Kraken",
        value="SEA",
    ),
    schema.Option(
        display="St. Louis Blues",
        value="STL",
    ),
    schema.Option(
        display="Tampa Bay Lightning",
        value="TB",
    ),
    schema.Option(
        display="Toronto Maple Leafs",
        value="TOR",
    ),
    schema.Option(
        display="Vancouver Canucks",
        value="VAN",
    ),
    schema.Option(
        display="Vegas Golden Knights",
        value="VGK",
    ),
    schema.Option(
        display="Washington Capitals",
        value="WSH",
    ),
    schema.Option(
        display="Winnipeg Jets",
        value="WPG",
    ),
]
