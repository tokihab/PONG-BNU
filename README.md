# PONG-BNU
This repository features a Pong Game simulation developed using a microprocessor and assembly language. It focuses on real-time control, collision detection, and score tracking, offering practical experience in low-level programming, assembly language, and efficient resource management for embedded systems.

# PONG-BNU
This repository features a Pong Game simulation developed using a microprocessor and assembly language. It focuses on real-time control, collision detection, and score tracking, offering practical experience in low-level programming, assembly language, and efficient resource management for embedded systems.

## Pong Game Simulation on DOSBox

This project simulates the Pong game using assembly language and is designed to run on DOSBox. Follow the steps below to run it:

### Steps to Run:

1. **Mount the directory** (replace `d:\toni\courses\8086PONG` with your actual project path): `mount d d:\toni\courses\8086PONG`

2. **Switch to the mounted drive**: D:

3. **Assemble the program**:
Run the following command to assemble the program: `masm /a pong.asm`

### MASM Command Explanation

The following command is used to assemble the Pong game code: `masm /a pong.asm`

`masm`: Runs the MASM tool, which converts the Pong game code (written in assembly language) into machine code that the computer can understand and execute.

`/a`: This option tells MASM to generate the necessary output files for the game to function properly.

`pong.asm`: The assembly language source file that contains the instructions for the Pong game.

Press **Enter**, then use **;** to skip error checks. Once it's done, run: `link pong`

4. **Run the game**:
Type pong and press **Enter** to start the game.

Enjoy playing Pong!
