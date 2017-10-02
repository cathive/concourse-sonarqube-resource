package com.example;

public class Main {
	/**
	 * @param argx Parameter with typo
	 * @return
	 *   Actually nothing, but we want to test SonarQube.
	 */
	public static void main(String ... args) {
		// TODO Fix something. Let's see if SonarQube finds this marker.

		args = null; // Should trigger yet another warning.
		if (args != null) {
			System.out.println("Impossible!!!1");
		}
	}
}
