from fwgp.plugins.base import BasePlugin, PluginManifest


class HelloPlugin(BasePlugin):
    manifest = PluginManifest(name="HelloPlugin", version="0.1.0", description="logs file events")

    def onFileDetected(self, evt, ctx):
        logger = ctx.get("logger")
        if logger:
            logger.info("[HelloPlugin] %s %s", evt.change_type, evt.path)

