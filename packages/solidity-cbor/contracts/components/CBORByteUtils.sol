//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Helpful byte utility functions.
 *
 */
library CBORByteUtils {

    /**
     * @dev Slices a dynamic bytes object from start:end (non-inclusive end)
     * @dev copied from https://github.com/GNSPS/solidity-bytes-utils/blob/master/contracts/BytesLib.sol
     * @param _start position to start byte slice (inclusive)
     * @param _end position to end byte slice (non-inclusive)
     * @return slicedData dynamic sliced bytes object
     */
    function sliceBytesMemory(
        bytes memory _data,
        uint _start,
        uint _end
    ) internal pure returns (
        bytes memory slicedData
    ) {
        uint256 _length = _end - _start;
        require(_length + 31 >= _length, "slice_overflow");
        require(_data.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_data, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    /**
     * @dev Converts a dynamic bytes array to a uint256
     * @param data dynamic bytes array
     * @return value calculated uint256 value
     */
    function bytesToUint256(
        bytes memory data
    ) internal pure returns (
        uint256 value
    ) {
        for (uint i = 0; i < data.length; i++)
            value += uint8(data[i])*(2**(8*(data.length-(i+1))));
    }

}
