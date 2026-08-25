{...}: {
  programs.newsboat = {
    enable = true;
    urls = [
      {url = "https://xkcd.com/rss.xml";}
      {url = "https://alexjercan.github.io/rss.xml";}
    ];
  };
}
