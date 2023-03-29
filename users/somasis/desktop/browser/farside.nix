# Redirect certain sites to open-source proxies
# Derived from <https://github.com/Phantop/dotfiles/blob/d561366659c5aea1846f49d5186dd178058f7268/qutebrowser/redirects.py>
{
  programs.qutebrowser.extraConfig = ''
    from qutebrowser.api import interceptor
    from urllib.parse import urljoin
    from PyQt5.QtCore import QUrl
    import operator

    o = operator.methodcaller
    s = "setHost"
    i = interceptor

    def farside(url: QUrl, r) -> bool:
        url.setHost("farside.link")
        p = url.path().strip("/")
        url.setPath(urljoin(r, p))
        return True

    redirects = [
        "imgur.com",
        "medium.com",
        "tiktok.com",
        "www.tiktok.com"
    ]

    def f(info: i.Request):
        if info.resource_type != i.ResourceType.main_frame or info.request_url.scheme() in {
            "data",
            "blob",
        }:
            return

        url = info.request_url
        if url.host() in redirects:
            info.redirect(farside(url, url.host()))

    i.register(f)
  '';
}
