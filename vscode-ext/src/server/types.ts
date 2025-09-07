import { Position, Range } from 'vscode';

export interface BMathType {
    name: string;
    kind: BMathTypeKind;
}

export enum BMathTypeKind {
    Integer = 'integer',
    Real = 'real',
    Complex = 'complex',
    Boolean = 'boolean',
    Vector = 'vector',
    Sequence = 'sequence',
    Function = 'function',
    Any = 'any',
    Number = 'number',
    Type = 'type',
    Error = 'error'
}

export interface BMathSymbol {
    name: string;
    type: BMathType;
    range: Range;
    position: Position;
}

export interface BMathVariable {
    name: string;
    type: BMathType;
    value: any;
}

export interface BMathFunction {
    name: string;
    parameters: BMathVariable[];
    returnType: BMathType;
    body: string; // This could be an AST node in a more complex implementation
}

export interface BMathError {
    message: string;
    range: Range;
}