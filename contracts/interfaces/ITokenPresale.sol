//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ITokenPresale {
    event SetBeneficiary(address beneficiary);
    event SetMinPurchase(uint256 min);
    event SetPrice(uint256 tokenPrice);
    event TokensPurchased(
        address indexed purchaser,
        address indexed beneficiary,
        address paymentToken,
        uint256 usdAmount,
        uint256 tokensAmount
    );
    event Released(address recipient, uint256 amount);
    event Withdraw(address token, uint256 amount);

    // modify
    function acceptPaymentTokens(address[] calldata addresses_) external;

    function cancelPaymentTokens(address[] calldata addresses_) external;

    function finalize(bool status_) external;

    function setBeneficiary(address beneficiary_) external;

    function setMinPursechase(uint256 minPurchase_) external;

    function setTokenPrice(uint256 newPrice) external;

    function buy(address paymentToken_, uint256 weiAmount_) external payable;

    function buyExactTokens(address paymentToken_, uint256 tokenAmount_) external payable;

    function claim() external;

    function ownerClaim(address[] calldata beneficiaries_) external;

    function withdrawToken(address token_, uint256 amount_) external;

    // view

    function getWithdrawableAmount() external view returns (uint256);
}
