# H6x

H6x is a script sandboxing tool designed with compatability and security in mind.

## Here be dragons

If the security of your game's data/playability is a concern to you, please take a moment to read the following carefully before you proceed, and make considerations.

While H6x itself is designed to be secure as a sandboxing tool, that does not mean that insecure/improper usage is impossible and can't exist.

H6x is merely a tool for constructing sandboxes & environments to run trusted, or untrusted code in. While it intends to be user friendly, and make it easy to securely execute untrusted code, you should be aware of the risks of doing so, and the ways in which you may provide unwanted access to pieces of your game.

Avoid providing more than you explicitly intend to provide. For example, if you intend to allow users to create mods for your game, it is recommended that you create a unique and entirely separate API that interacts with internal ones indirectly. You should avoid letting untrusted code interact directly with important code, and you should sanitize function arguments.

Metatables and function environments (fenvs) are important to take into account if security is of concern to you. When you call H6x APIs, H6x executes code inside of individual container scripts, which stops user code from accessing caller envs by simply taking advantage of Roblox's own functionality, but, calling user functions directly without the use of H6x APIs can allow access to your caller scripts' fenvs. If you want to be extra safe, you can always disable these features if you don't intend to let untrusted code use them.

## Getting Started

### Importing H6x

1. Download a release from [releases](/releases) or see [Building from source](#building-from-source).
2. Import the rbxm you downloaded/built into your game.
3. Run the game, and ensure that H6x does not display any errors in the Output view (Roblox Studio -> View -> Output)

### Setting up H6x in your game

TBD

## Building from source

To build H6x, first install Rojo, or use Foreman, and run the following command once you have cloned the repository:

```bash
rojo build -o "H6x.rbxm"
```

For more help, check out [the Rojo documentation](https://rojo.space/docs).