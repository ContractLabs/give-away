// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// clear stuck token in contract
abstract contract Withdrawable is Ownable {
    event Withdraw(address indexed token, uint256 amount);

    using SafeERC20 for IERC20;

    function __transfer(address asset_, address to_, uint256 amount_) internal {
        if (amount_ == 0) return;
        if (to_ == address(0)) return;
        if (asset_ == address(0) && to_ != address(this)) {
            (bool success, ) = payable(to_).call{ value: amount_ }(new bytes(0));
            require(success, "INSUFICIENT_BALANCE");
        } else {
            IERC20(asset_).safeTransfer(to_, amount_);
        }
    }

    function __transferFrom(address asset_, address from_, address to_, uint256 amount_, uint256 msgValue_) private {
        if (amount_ == 0) return;
        if (asset_ == address(0)) {
            require(msgValue_ >= amount_, "INSUFICIENT_BALANCE");
        } else IERC20(asset_).safeTransferFrom(from_, to_, amount_);
    }
}
