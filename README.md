# What is this plugin?

Attempts to add support for embedded devices like the Anbernic RG34XX.

Inside the `/launch` folder, you'll see my current work in progress for the scripts required to launch this game on the device.

The current method kind of works, but still requries installing Xorg. This is an issue because Xorg and Wayland cannot be assumed to be on every device, nor are they commonly on embedded devices like the Anbernic linux handhelds.

## Notes

- As of testing on the RG34XX, it seems like the default launcher for the device writes directly to the framebuffer.

## Research

- [Godot FRT Export](https://github.com/efornara/frt)
- [PortMaster.games](https://portmaster.games/)
