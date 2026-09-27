import java.math.BigDecimal;
import java.util.Scanner;

public class bankingSystem {
	private static final Scanner INPUT = new Scanner(System.in);
	private static BigDecimal balance = BigDecimal.ZERO;

	public static void main(String[] args) {
		System.out.println("=== Simple Banking System ===");
		System.out.print("Enter account holder name: ");
		String accountHolder = INPUT.nextLine().trim();

		while (accountHolder.isEmpty()) {
			System.out.print("Name cannot be empty. Enter account holder name: ");
			accountHolder = INPUT.nextLine().trim();
		}

		boolean running = true;
		while (running) {
			showMenu(accountHolder);
			String choice = INPUT.nextLine().trim();

			switch (choice) {
				case "1":
					System.out.println("Current balance: $" + balance);
					break;
				case "2":
					deposit();
					break;
				case "3":
					withdraw();
					break;
				case "4":
					System.out.println("Thank you for using the banking system.");
					running = false;
					break;
				default:
					System.out.println("Invalid choice. Please select 1-4.");
			}
		}
	}

	private static void showMenu(String accountHolder) {
		System.out.println("\nAccount: " + accountHolder);
		System.out.println("1. Check balance");
		System.out.println("2. Deposit money");
		System.out.println("3. Withdraw money");
		System.out.println("4. Exit");
		System.out.print("Choose an option: ");
	}

	private static void deposit() {
		BigDecimal amount = readPositiveAmount("Enter deposit amount: $");
		if (amount != null) {
			balance = balance.add(amount);
			System.out.println("Deposit successful. New balance: $" + balance);
		}
	}

	private static void withdraw() {
		BigDecimal amount = readPositiveAmount("Enter withdrawal amount: $");
		if (amount == null) {
			return;
		}

		if (amount.compareTo(balance) > 0) {
			System.out.println("Insufficient funds. Current balance: $" + balance);
			return;
		}

		balance = balance.subtract(amount);
		System.out.println("Withdrawal successful. New balance: $" + balance);
	}

	private static BigDecimal readPositiveAmount(String prompt) {
		System.out.print(prompt);
		String input = INPUT.nextLine().trim();

		try {
			BigDecimal amount = new BigDecimal(input);
			if (amount.compareTo(BigDecimal.ZERO) <= 0) {
				System.out.println("Amount must be greater than zero.");
				return null;
			}
			return amount.setScale(2, java.math.RoundingMode.UNNECESSARY);
		} catch (NumberFormatException | ArithmeticException exception) {
			System.out.println("Enter a valid amount with no more than two decimal places.");
			return null;
		}
	}
}
