// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";

contract SupplyChainMonitor {
    using Strings for uint256;

    address public government;

    constructor() {
        government = msg.sender;
    }

    event PDIResult(string message);
    event PHCIResult(string message);
    event APCDResult(string message);

    struct Invoice {
        uint256 productId;
        uint256 actualCostPrice;
        uint256 actualMaxProfit;
        uint256 actualVAT;
        uint256 currentSalePrice;
        uint256 currentSaleVAT;
        uint256 totalPurchased;
        uint256 currentStock;
    }

    Invoice public currentInvoice;
    uint256 public apcdThresholdPercent = 50;

    modifier onlyGovernment() {
        require(msg.sender == government, "Only government can perform this action");
        _;
    }

    function setAPCDThresholdPercent(uint256 newPercent) public onlyGovernment {
        apcdThresholdPercent = newPercent;
    }

    function inputInvoice(
        uint256 productId,
        uint256 actualCostPrice,
        uint256 actualMaxProfit,
        uint256 actualVAT,
        uint256 currentSalePrice,
        uint256 currentSaleVAT,
        uint256 totalPurchased,
        uint256 currentStock
    ) public onlyGovernment {
        currentInvoice = Invoice({
            productId: productId,
            actualCostPrice: actualCostPrice,
            actualMaxProfit: actualMaxProfit,
            actualVAT: actualVAT,
            currentSalePrice: currentSalePrice,
            currentSaleVAT: currentSaleVAT,
            totalPurchased: totalPurchased,
            currentStock: currentStock
        });
    }

    function runPDI() public onlyGovernment {
        uint256 expectedPrice = currentInvoice.actualCostPrice + currentInvoice.actualMaxProfit;
        int256 priceDiff = int256(currentInvoice.currentSalePrice) - int256(expectedPrice);

        string memory message = string(
            abi.encodePacked("PDI: Price Difference = ", intToString(priceDiff))
        );

        if (priceDiff > 0) {
            emit PDIResult(string(abi.encodePacked(message, " (Overcharged)")));
        } else if (priceDiff < 0) {
            emit PDIResult(string(abi.encodePacked(message, " (Undercharged)")));
        } else {
            emit PDIResult(string(abi.encodePacked(message, " (Compliant)")));
        }
    }

    function runPHCI() public onlyGovernment {
        bool priceHike = currentInvoice.currentSalePrice >
            (currentInvoice.actualCostPrice + currentInvoice.actualMaxProfit);
        bool vatMismatch = currentInvoice.currentSaleVAT != currentInvoice.actualVAT;

        if (priceHike && vatMismatch) {
            emit PHCIResult("PHCI: Price Hike & VAT Mismatch (Corruption Suspected)");
        } else if (priceHike) {
            emit PHCIResult("PHCI: Price Hike Positive");
        } else if (vatMismatch) {
            emit PHCIResult("PHCI: VAT Mismatch Detected (Potential Fraud)");
        } else {
            emit PHCIResult("PHCI: No Price Hike or VAT Issue (Compliant)");
        }
    }

    function runAPCD() public onlyGovernment {
        if (currentInvoice.totalPurchased == 0) {
            emit APCDResult("APCD: No Purchase Data");
            return;
        }

        uint256 stockPercent = (currentInvoice.currentStock * 100) /
            currentInvoice.totalPurchased;
        string memory message = string(
            abi.encodePacked(
                "APCD: Stock Holding = ",
                stockPercent.toString(),
                "%"
            )
        );

        if (stockPercent > apcdThresholdPercent) {
    emit APCDResult(
        string(abi.encodePacked(message, " => Crisis Detected (Hoarding)"))
    );
} else {
    emit APCDResult(
        string(abi.encodePacked(message, " => Normal (Compliant)"))
    );
}

    }

    function intToString(int256 value) internal pure returns (string memory) {
        if (value >= 0) {
            return uint256(value).toString();
        } else {
            return string(abi.encodePacked("-", uint256(-value).toString()));
        }
    }
}
