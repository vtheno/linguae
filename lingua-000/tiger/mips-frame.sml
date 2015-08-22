structure MipsFrame :> FRAME =
struct
  open Fn
  infix 1 |>

  structure L = List

  (**
   * Where this local will be stored — stack frame or register.
   *)
  datatype access =
    InFrame of int          (* At offset X from the frame pointer. *)
  | InRegister of Temp.temp (* A register name. *)

  datatype frame =
    StackFrame of {
      (* Address of the function that this frame belongs to. *)
      label : Temp.label,
      (* Formal parameter accesses. *)
      formals : access list,
      (* Total number of formals and locals this frame stores. *)
      inFrameCount : int ref
      (* TODO: implement view-shift *)
    }

  (*
   * The MIPS calling conventions reserves 4 registers for procedure arguments,
   * from $a0 to $a3. Extra arguments will be passed in the stack frame.
   *)
  val maxFormalsInRegisters = 4

  val outermost = StackFrame {
    label = Temp.newLabel (),
    formals = [],
    inFrameCount = ref 0
  }

  fun getAndIncrement refCell =
    !refCell before (refCell := !refCell + 1)

  (*
   * Allocates a new stack frame for a function named `name`. The `formals`
   * list tells which of the arguments, identified by position, escapes.
   *)
  fun newFrame { name, formals } =
    let
      (*
       * The argument count starts from 3, because the minimum stack frame
       * layout on MIPS must include space for the four arguments passed
       * via registers. Also, we're indexing from 0.
       *)
      val frameArgsCount = ref maxFormalsInRegisters

      (* Put first four arguments in registers, the rest in the frame. *)
      fun allocFormal (escapes, index) =
        if index < maxFormalsInRegisters
        (*
         * MIPS calling conventions reserve four registers for arguments.
         * Please note that we don't allocate any of the four arguments on
         * the stack, even if they escape, because the same calling conventions
         * mandate a frame layout which already accomodates spilling of the
         * four arguments.
         *
         * The minimum stack frame size on MIPS is 24 bytes. Four slots are
         * reserved for the four arguments passed in registers, plus 8 bytes
         * of padding because the stack pointer must be 8-byte aligned.
         *)
        then InRegister (Temp.newTemp ())
        (* The rest of the arguments will have to be passed on the stack. *)
        else InFrame (getAndIncrement frameArgsCount)

      fun allocFormals formals =
        ListPair.zipWithIndex formals |> List.map allocFormal
    in
      StackFrame {
        label = name,
        formals = allocFormals formals,
        inFrameCount = frameArgsCount
      }
    end

  fun formals (StackFrame { formals, ... }) = formals

  fun allocLocal (StackFrame { inFrameCount, ... }) escapes =
    if escapes
    then InFrame (getAndIncrement inFrameCount)
    else InRegister (Temp.newTemp ())
end