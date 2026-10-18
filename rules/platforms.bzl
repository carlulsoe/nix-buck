def _remote_platform_impl(ctx):
    platform = ExecutionPlatformInfo(
        label = ctx.label.raw_target(),
        configuration = ConfigurationInfo(constraints = {}, values = {}),
        # Every command runs on a worker; nothing builds on this machine.
        executor_config = CommandExecutorConfig(
            local_enabled = False,
            remote_enabled = True,
            use_limited_hybrid = False,
            remote_execution_properties = {
                "OSFamily": "linux",
                "container-image": "",
            },
            remote_execution_use_case = "buck2-default",
        ),
    )
    return [
        DefaultInfo(),
        ExecutionPlatformRegistrationInfo(platforms = [platform]),
    ]

remote_platform = rule(impl = _remote_platform_impl, attrs = {})
