# Hosting Your Privacy Policy on GitHub Pages

Since the Google Play Store requires a public URL for your Privacy Policy, hosting it on GitHub Pages is a free and reliable solution. Follow these steps to host your `PRIVACY_POLICY.html` file.

## Step 1: Create a New GitHub Repository
1. Log in to [GitHub](https://github.com).
2. Click the **+** icon in the top right and select **New repository**.
3. Name it something like `evergreen-privacy`.
4. Set it to **Public** (Privacy policies must be public).
5. Click **Create repository**.

## Step 2: Upload the File
1. In your new repository, click **uploading an existing file**.
2. Select the `PRIVACY_POLICY.html` file from the `playstore_assets` folder.
3. Scroll down and click **Commit changes**.

## Step 3: Enable GitHub Pages
1. Go to the **Settings** tab of your repository.
2. Click on **Pages** in the left-hand sidebar.
3. Under **Build and deployment > Branch**, ensure the branch is set to `main` (or `master`) and the folder is set to `/(root)`.
4. Click **Save**.

## Step 4: Get Your URL
1. After a minute, refresh the **Pages** settings page.
2. You will see a banner that says: "Your site is live at `https://<your-username>.github.io/evergreen-privacy/`."
3. **The Final Privacy Policy URL**: `https://<your-username>.github.io/evergreen-privacy/PRIVACY_POLICY.html`

> [!IMPORTANT]
> Copy this URL and paste it into the **Privacy Policy** section of the Google Play Console under **App Content**.
