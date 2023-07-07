namespace InterviewChallenge
{
    class Program
    {
        static void Main()
        {
            // I added a bunch of tests. Feel free to adjust as needed. 

            double SendIt;

            // Test 1: The example provided by Nate
            SendIt = GetPrice(2000, new string[] { "FININTAC", "DENTS" });
            Console.WriteLine($"Test 1: {SendIt}");

            // Test 2: What if its null
            SendIt = GetPrice(2000, null);
            Console.WriteLine($"Test 2: {SendIt}");

            // Test 3: What if no attributes are sent
            SendIt = GetPrice(2000);
            Console.WriteLine($"Test 3: {SendIt}");

            // Test 4: What if the unfinished attribute is sent
            SendIt = GetPrice(2000, new string[] { "UNFIN" });
            Console.WriteLine($"Test 4: {SendIt}");

            // Test 5: What if lots of values are sent
            SendIt = GetPrice(2000, new string[] { "FININTAC", "DENTS", "WBRUSH", "PRIME/SV", "SPLITS" });
            Console.WriteLine($"Test 5: {SendIt}");

            // Test 6: What if an attribute is sent multiple times
            SendIt = GetPrice(2000, new string[] { "SPLITS", "DENTS", "WBRUSH", "PRIME/SV", "SPLITS", "SPLITS" });
            Console.WriteLine($"Test 6: {SendIt}");

            // Test 7: What if a blank is sent at the end
            SendIt = GetPrice(2000, new string[] { "FININTAC", "DENTS", "WBRUSH", "PRIME/SV", "SPLITS", });
            Console.WriteLine($"Test 7: {SendIt}");

            // Test 8: What if a null is sent at the end
            SendIt = GetPrice(2000, new string[] { "FININTAC", "DENTS", "WBRUSH", "PRIME/SV", "SPLITS", null });
            Console.WriteLine($"Test 8: {SendIt}");

            // Test 9: What is data outside of the customer attributes are sent
            SendIt = GetPrice(2000, new string[] { "FININTAC", "DENTS", "WBRUSH", "PRIME/SV", "SPLITS", "FAKE" });
            Console.WriteLine($"Test 9: {SendIt}");

            // Test 10: What if the end amount is lower than the minimum set price
            SendIt = GetPrice(10, new string[] { "FININTAC", "DENTS", "WBRUSH" });
            Console.WriteLine($"Test 10: {SendIt}");
        }

        /// <summary>
        /// Gets the calculated adjusted price based on selected attributes
        /// </summary>
        /// <param name="Price">Initial price</param>
        /// <param name="Attributes">Selected attributes</param>
        /// <returns>Double</returns>
        public static double GetPrice(double Price, params string[]? Attributes)
        {
            // Filtered attribute list based on array or attributes that are sent; If null or 0 attributes sent, return the default variable
            List<AttributeSpec> FilteredAttributes = Attributes == null || Attributes.Length == 0
                ? ListOfAttributes().Where(x => x.Abbr == DefaultFinish).ToList()
                : ListOfAttributes().Where(x => Attributes.Contains(x.Abbr)).ToList();

            // Sets the two rates that get applied. The most expensive and the standard
            double HighestRateCost = FilteredAttributes.Max(x => x.Rate) * Price; // The largest adjustment cost
            double StandardRateCost = StandardRate * Price; // This gets the standard cost that is applied to each attribute after the highest priced attribute is added

            // Gets any additional attributes added using the standard adjustment
            double TotalAdditionalCost = 0;
            for (int i = 0; i < FilteredAttributes.Count - 1; i++) { TotalAdditionalCost += StandardRateCost; }

            // Sets the Final price by adding the initial price + highest rate cost + any additional costs using the standard rate
            double FinalPrice = Price + HighestRateCost + TotalAdditionalCost;

            // Checks to see if the final result is below the minimum price that is allowed
            if (FinalPrice < MinimumPrice) { FinalPrice = MinimumPrice; };

            // Return the final price
            return FinalPrice;
        }

        /// <summary>
        /// The minimum price allowed
        /// </summary>
        public static double MinimumPrice = 300;

        /// <summary>
        /// The default attribute when no attributes are selected
        /// </summary>
        public static string DefaultFinish = "UNFIN";

        /// <summary>
        /// The standard rate after the highest rate has been applied
        /// </summary>
        public static double StandardRate = .01;

        /// <summary>
        /// Attributes and rates for products
        /// </summary>
        private class AttributeSpec
        {
            public string? Abbr { get; set; }
            public double Rate { get; set; }
        }

        /// <summary>
        /// Attributes and rates provided by the customer
        /// </summary>
        /// <returns></returns>
        private static List<AttributeSpec> ListOfAttributes()
        {
            return new()
                    {
                        new AttributeSpec() {Abbr = "UNFIN", Rate = -.05 },
                        new AttributeSpec() {Abbr = "SBI", Rate = .1 },
                        new AttributeSpec() {Abbr = "PBI", Rate = .1},
                        new AttributeSpec() {Abbr = "FININTSP", Rate = .2},
                        new AttributeSpec() {Abbr = "FININTAC", Rate = .3},
                        new AttributeSpec() {Abbr = "ACIB", Rate = .2},
                        new AttributeSpec() {Abbr = "PRIME/SV", Rate = 0},
                        new AttributeSpec() {Abbr = "PRIME", Rate = 0},
                        new AttributeSpec() {Abbr = "EASED", Rate = .03},
                        new AttributeSpec() {Abbr = "RUB", Rate = .03},
                        new AttributeSpec() {Abbr = "DENTS", Rate = .03},
                        new AttributeSpec() {Abbr = "SPLITS", Rate = .03},
                        new AttributeSpec() {Abbr = "WORMHOLES", Rate = .03},
                        new AttributeSpec() {Abbr = "RASP", Rate = .03},
                        new AttributeSpec() {Abbr = "SPATTER", Rate = .03},
                        new AttributeSpec() {Abbr = "COWTAIL", Rate = .03},
                        new AttributeSpec() {Abbr = "WBRUSH", Rate = .08},
                    };
        }
    }
}